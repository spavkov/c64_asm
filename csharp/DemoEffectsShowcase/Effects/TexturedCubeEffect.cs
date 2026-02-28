using DemoEffectsShowcase.Core;
using System.Drawing;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class TexturedCubeEffect : DemoSceneEffect
{
    // Eight 3D points of a unit cube centered at origin.
    private static readonly Vector3[] CubeVertices =
    [
        new(-1, -1, -1),
        new(1, -1, -1),
        new(1, 1, -1),
        new(-1, 1, -1),
        new(-1, -1, 1),
        new(1, -1, 1),
        new(1, 1, 1),
        new(-1, 1, 1)
    ];

    // Faces are vertex-index quads listed clockwise.
    private static readonly int[][] Faces =
    [
        [0, 1, 2, 3],
        [5, 4, 7, 6],
        [4, 0, 3, 7],
        [1, 5, 6, 2],
        [4, 5, 1, 0],
        [3, 2, 6, 7]
    ];

    private int _width;
    private int _height;
    private double _time;
    private float _speed = 1f;
    private float _density = 7f;
    private float _zoom = 1f;
    private readonly byte[] _texture;
    private readonly int _textureWidth;
    private readonly int _textureHeight;
    private readonly IReadOnlyList<EffectParameterDefinition> _params;

    public TexturedCubeEffect()
    {
        (_textureWidth, _textureHeight, _texture) = LoadTexture();
        _params =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.2f, 3f),
            EffectParameters.Float("density", "Texture Density", () => _density, v => _density = v, 3f, 16f),
            EffectParameters.Float("zoom", "Zoom", () => _zoom, v => _zoom = v, 0.6f, 2.2f)
        ];
    }

    public string Id => "textured-cube";
    public string Name => "Textured Cube";
    public string Description => "Rotating cube textured on all faces.";
    public IReadOnlyList<string> Tags => ["cube", "texture", "mapped"];

    public void Initialize(in EffectInitContext context) => Resize(context.Width, context.Height);

    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
    }

    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        var center = new Vector2(_width * 0.5f, _height * 0.5f);
        var zoom = Math.Clamp(_zoom, 0.6f, 2.2f);
        var size = MathF.Min(_width, _height) * 0.23f * zoom;
        var angle = (float)_time;
        var cameraDistance = 3.2f;

        var projected = new Vector2[CubeVertices.Length];
        var rotated = new Vector3[CubeVertices.Length];

        // Rotate and project all cube vertices.
        for (var i = 0; i < CubeVertices.Length; i++)
        {
            var rotatedPoint = RotateAroundAxes(CubeVertices[i], angle * 0.9f, angle * 1.2f, angle * 0.7f);
            rotated[i] = rotatedPoint;

            // Perspective projection: divide x/y by depth.
            var depth = MathF.Max(0.25f, cameraDistance + rotatedPoint.Z);
            projected[i] = new Vector2(
                center.X + rotatedPoint.X / depth * size,
                center.Y + rotatedPoint.Y / depth * size);
        }

        var cameraPos = new Vector3(0f, 0f, -cameraDistance);

        // Backface culling:
        // keep only faces with normals pointing toward the camera.
        var faceOrder = Enumerable.Range(0, Faces.Length)
            .Where(faceIndex =>
            {
                var face = Faces[faceIndex];
                var a = rotated[face[0]];
                var b = rotated[face[1]];
                var c = rotated[face[2]];
                var d = rotated[face[3]];
                var normal = Vector3.Cross(b - a, c - a);
                var center3D = (a + b + c + d) * 0.25f;
                return Vector3.Dot(normal, cameraPos - center3D) < 0f;
            })
            .OrderByDescending(faceIndex =>
            {
                var face = Faces[faceIndex];
                return (rotated[face[0]].Z + rotated[face[1]].Z + rotated[face[2]].Z + rotated[face[3]].Z) * 0.25f;
            });

        var step = Math.Max(1, 18 / Math.Clamp((int)_density, 3, 16));
        foreach (var faceIndex in faceOrder)
        {
            var face = Faces[faceIndex];
            var a = projected[face[0]];
            var b = projected[face[1]];
            var c = projected[face[2]];
            var d = projected[face[3]];
            DrawTexturedFace(renderer, a, b, c, d, step);
            DrawFaceOutline(renderer, a, b, c, d);
        }
    }

    public void Dispose()
    {
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _params;

    private void DrawTexturedFace(IntPtr renderer, Vector2 a, Vector2 b, Vector2 c, Vector2 d, int step)
    {
        var minX = (int)MathF.Floor(MathF.Min(MathF.Min(a.X, b.X), MathF.Min(c.X, d.X)));
        var maxX = (int)MathF.Ceiling(MathF.Max(MathF.Max(a.X, b.X), MathF.Max(c.X, d.X)));
        var minY = (int)MathF.Floor(MathF.Min(MathF.Min(a.Y, b.Y), MathF.Min(c.Y, d.Y)));
        var maxY = (int)MathF.Ceiling(MathF.Max(MathF.Max(a.Y, b.Y), MathF.Max(c.Y, d.Y)));

        minX = Math.Clamp(minX, 0, _width - 1);
        maxX = Math.Clamp(maxX, 0, _width - 1);
        minY = Math.Clamp(minY, 0, _height - 1);
        maxY = Math.Clamp(maxY, 0, _height - 1);

        // Fill the projected quad with many small blocks.
        // For each block center, convert screen point -> face UV -> texture color.
        for (var y = minY; y <= maxY; y += step)
        {
            for (var x = minX; x <= maxX; x += step)
            {
                var samplePoint = new Vector2(x + step * 0.5f, y + step * 0.5f);
                if (!TryGetUv(a, b, c, d, samplePoint, out var u, out var v))
                {
                    continue;
                }

                var tx = Math.Clamp((int)(u * (_textureWidth - 1)), 0, _textureWidth - 1);
                var ty = Math.Clamp((int)(v * (_textureHeight - 1)), 0, _textureHeight - 1);
                var textureIndex = (ty * _textureWidth + tx) * 3;
                SdlFx.FillRect(renderer, x, y, step, step, _texture[textureIndex], _texture[textureIndex + 1], _texture[textureIndex + 2]);
            }
        }
    }

    private static void DrawFaceOutline(IntPtr renderer, Vector2 a, Vector2 b, Vector2 c, Vector2 d)
    {
        const byte edge = 28;
        SdlFx.Line(renderer, (int)a.X, (int)a.Y, (int)b.X, (int)b.Y, edge, edge, edge);
        SdlFx.Line(renderer, (int)b.X, (int)b.Y, (int)c.X, (int)c.Y, edge, edge, edge);
        SdlFx.Line(renderer, (int)c.X, (int)c.Y, (int)d.X, (int)d.Y, edge, edge, edge);
        SdlFx.Line(renderer, (int)d.X, (int)d.Y, (int)a.X, (int)a.Y, edge, edge, edge);
    }

    private static (int Width, int Height, byte[] Data) LoadTexture()
    {
        var texturePath = Path.Combine(AppContext.BaseDirectory, "textures", "tunnelstonetex.png");
        if (!File.Exists(texturePath))
        {
            throw new InvalidOperationException($"Missing texture file: {texturePath}");
        }

        using var bitmap = new Bitmap(texturePath);
        var width = bitmap.Width;
        var height = bitmap.Height;
        var data = new byte[width * height * 3];

        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var color = bitmap.GetPixel(x, y);
                var i = (y * width + x) * 3;
                data[i] = color.R;
                data[i + 1] = color.G;
                data[i + 2] = color.B;
            }
        }

        return (width, height, data);
    }

    private static bool TryGetUv(Vector2 a, Vector2 b, Vector2 c, Vector2 d, Vector2 point, out float u, out float v)
    {
        // Split quad into two triangles and find barycentric coordinates.
        if (TryBarycentric(a, b, c, point, out var w1, out var w2, out var w3))
        {
            u = w2 + w3;
            v = w3;
            return true;
        }

        if (TryBarycentric(a, c, d, point, out w1, out w2, out w3))
        {
            u = w2;
            v = w2 + w3;
            return true;
        }

        u = v = 0;
        return false;
    }

    private static bool TryBarycentric(Vector2 a, Vector2 b, Vector2 c, Vector2 point, out float w1, out float w2, out float w3)
    {
        var denominator = ((b.Y - c.Y) * (a.X - c.X) + (c.X - b.X) * (a.Y - c.Y));
        if (MathF.Abs(denominator) < 0.0001f)
        {
            w1 = w2 = w3 = 0;
            return false;
        }

        w1 = ((b.Y - c.Y) * (point.X - c.X) + (c.X - b.X) * (point.Y - c.Y)) / denominator;
        w2 = ((c.Y - a.Y) * (point.X - c.X) + (a.X - c.X) * (point.Y - c.Y)) / denominator;
        w3 = 1f - w1 - w2;
        return w1 >= 0f && w2 >= 0f && w3 >= 0f;
    }

    private static Vector3 RotateAroundAxes(Vector3 p, float ax, float ay, float az)
    {
        var (sx, cx) = MathF.SinCos(ax);
        var (sy, cy) = MathF.SinCos(ay);
        var (sz, cz) = MathF.SinCos(az);

        var y1 = p.Y * cx - p.Z * sx;
        var z1 = p.Y * sx + p.Z * cx;
        var x2 = p.X * cy + z1 * sy;
        var z2 = -p.X * sy + z1 * cy;
        return new Vector3(x2 * cz - y1 * sz, x2 * sz + y1 * cz, z2);
    }
}

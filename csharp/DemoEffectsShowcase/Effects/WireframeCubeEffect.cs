using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class WireframeCubeEffect : DemoSceneEffect
{
    // The cube starts as 8 points around (0, 0, 0).
    // Think of these as "local" points before any animation is applied.
    // Each value is either -1 or +1, which describes a unit cube.
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

    // Each tuple says: draw a line from vertex A to vertex B.
    // Together these 12 pairs produce all visible wireframe edges of a cube.
    private static readonly (int A, int B)[] CubeEdges =
    [
        (0, 1), (1, 2), (2, 3), (3, 0),
        (4, 5), (5, 6), (6, 7), (7, 4),
        (0, 4), (1, 5), (2, 6), (3, 7)
    ];

    private int _width;
    private int _height;
    private double _time;
    private float _speed = 1f;
    private float _lineWidth = 2f;
    private Vector3 _color = new(0.63f, 0.86f, 1f);
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;

    public WireframeCubeEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.2f, 4f),
            EffectParameters.Float("line", "Line Width", () => _lineWidth, v => _lineWidth = v, 0.5f, 5f),
            EffectParameters.Color3("color", "Line Color", () => _color, v => _color = v)
        ];
    }

    public string Id => "wireframe-cube";
    public string Name => "Wireframe Cube";
    public string Description => "Classic rotating 3D wireframe cube.";
    public IReadOnlyList<string> Tags => ["wireframe", "cube", "vector"];

    public void Initialize(in EffectInitContext context)
    {
        Resize(context.Width, context.Height);
    }

    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
    }

    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        // We store final 2D points here after converting each 3D cube point.
        var projectedPoints = new Vector2[CubeVertices.Length];

        // Middle of the window; this is where the cube is centered on screen.
        var screenCenter = new Vector2(_width * 0.5f, _height * 0.5f);

        // Controls how large the cube appears. Smaller screen dimension is used
        // so the cube keeps a similar size even when the window is not square.
        var screenScale = MathF.Min(_width, _height) * 0.23f;

        // Angle values change over time, causing continuous rotation.
        // Different multipliers make motion less mechanical and more interesting.
        var angleX = (float)_time * 0.9f;
        var angleY = (float)_time * 1.2f;
        var angleZ = (float)_time * 0.7f;

        for (var i = 0; i < CubeVertices.Length; i++)
        {
            // 1) Rotate point in 3D space around X, Y, and Z axes.
            var rotated = RotateAroundAxes(CubeVertices[i], angleX, angleY, angleZ);

            // 2) Convert that rotated 3D point into a 2D screen position.
            projectedPoints[i] = ProjectToScreen(rotated, screenCenter, screenScale);
        }

        // Convert normalized color components (0..1) into byte values (0..255).
        var red = (byte)(_color.X * 255);
        var green = (byte)(_color.Y * 255);
        var blue = (byte)(_color.Z * 255);

        foreach (var edge in CubeEdges)
        {
            // Draw one edge between two projected points.
            // After all edges are drawn, we see the full wireframe cube.
            SdlFx.Line(
                renderer,
                (int)projectedPoints[edge.A].X,
                (int)projectedPoints[edge.A].Y,
                (int)projectedPoints[edge.B].X,
                (int)projectedPoints[edge.B].Y,
                red,
                green,
                blue);
        }
    }

    public void Dispose()
    {
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

    private static Vector2 ProjectToScreen(Vector3 point, Vector2 screenCenter, float screenScale)
    {
        // Perspective projection:
        // - Larger depth means farther away and therefore smaller on screen.
        // - Adding a positive constant keeps the divider safely above zero.
        // - If depth gets bigger, x/depth and y/depth get smaller.
        //   That is the key idea that creates a "3D look" on a 2D display.
        var depth = 3.2f + point.Z;

        // Move projected point so (0,0,0) maps to the center of the screen.
        var x = screenCenter.X + (point.X / depth) * screenScale;
        var y = screenCenter.Y + (point.Y / depth) * screenScale;
        return new Vector2(x, y);
    }

    private static Vector3 RotateAroundAxes(Vector3 point, float angleX, float angleY, float angleZ)
    {
        // We rotate step-by-step around X, then Y, then Z.
        // This keeps the math approachable and easy to debug.
        var (sinX, cosX) = MathF.SinCos(angleX);
        var (sinY, cosY) = MathF.SinCos(angleY);
        var (sinZ, cosZ) = MathF.SinCos(angleZ);

        // Rotate around X axis:
        // X stays the same, Y and Z move in a circle.
        var yAfterX = point.Y * cosX - point.Z * sinX;
        var zAfterX = point.Y * sinX + point.Z * cosX;

        // Rotate around Y axis:
        // Y stays the same, X and Z move in a circle.
        var xAfterY = point.X * cosY + zAfterX * sinY;
        var zAfterY = -point.X * sinY + zAfterX * cosY;

        // Rotate around Z axis:
        // Z stays the same, X and Y move in a circle.
        var xAfterZ = xAfterY * cosZ - yAfterX * sinZ;
        var yAfterZ = xAfterY * sinZ + yAfterX * cosZ;

        return new Vector3(xAfterZ, yAfterZ, zAfterY);
    }
}

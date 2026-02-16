using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class VectorBallsEffect : DemoSceneEffect
{
    private readonly List<Vector3> _points = [];
    private int _width;
    private int _height;
    private double _time;
    private float _speed = 1.0f;
    private float _ballScale = 1.0f;
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;

    public VectorBallsEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.2f, 3.0f),
            EffectParameters.Float("scale", "Ball Scale", () => _ballScale, v => _ballScale = v, 0.4f, 2.0f)
        ];
    }

    public string Id => "vectorballs";
    public string Name => "Vectorballs";
    public string Description => "Rotating cloud of vector balls in 3D.";
    public IReadOnlyList<string> Tags => ["vectorballs", "3d", "balls"];

    public void Initialize(in EffectInitContext context)
    {
        Resize(context.Width, context.Height);
        _points.Clear();
        var latSteps = 13;
        var lonSteps = 24;
        for (var lat = 0; lat < latSteps; lat++)
        {
            var a = (lat / (float)(latSteps - 1) - 0.5f) * MathF.PI;
            var r = MathF.Cos(a);
            var y = MathF.Sin(a);
            for (var lon = 0; lon < lonSteps; lon++)
            {
                var b = lon / (float)lonSteps * MathF.PI * 2f;
                _points.Add(new Vector3(MathF.Cos(b) * r, y, MathF.Sin(b) * r));
            }
        }
    }

    public void Resize(int width, int height) { _width = Math.Max(1, width); _height = Math.Max(1, height); }
    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        var center = new Vector2(_width * 0.5f, _height * 0.5f);
        var scale = MathF.Min(_width, _height) * 0.25f;
        var ax = (float)_time * 0.7f;
        var ay = (float)_time * 1.2f;
        var az = (float)_time * 0.5f;
        var projected = new (Vector2 Pos, float Z)[_points.Count];
        for (var i = 0; i < _points.Count; i++)
        {
            var r = Rotate(_points[i], ax, ay, az);
            var depth = 3.0f + r.Z * 1.3f;
            projected[i] = (new Vector2(center.X + r.X / depth * scale, center.Y + r.Y / depth * scale), r.Z);
        }
        Array.Sort(projected, static (a, b) => a.Z.CompareTo(b.Z));

        var glowCenter = center + new Vector2(MathF.Sin((float)_time * 1.3f) * _width * 0.1f, MathF.Sin((float)_time * 0.9f + 1.4f) * _height * 0.08f);
        SdlFx.FilledCircle(renderer, (int)glowCenter.X, (int)glowCenter.Y, (int)(MathF.Min(_width, _height) * 0.22f), 45, 55, 95, 48);

        foreach (var p in projected)
        {
            var t = Math.Clamp((p.Z + 1.2f) / 2.4f, 0f, 1f);
            var radius = (1.6f + t * 5.4f) * _ballScale;
            SdlFx.FilledCircle(renderer, (int)p.Pos.X, (int)p.Pos.Y, (int)(radius * 1.9f), (byte)(70 + t * 90), (byte)(100 + t * 90), (byte)(220 + t * 25), (byte)(24 + t * 42));
            SdlFx.FilledCircle(renderer, (int)p.Pos.X, (int)p.Pos.Y, (int)radius, (byte)(90 + t * 150), (byte)(140 + t * 100), (byte)(255 - t * 70), (byte)(140 + t * 115));
        }
    }

    public void Dispose() { }
    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

    private static Vector3 Rotate(Vector3 p, float ax, float ay, float az)
    {
        var (sx, cx) = MathF.SinCos(ax); var (sy, cy) = MathF.SinCos(ay); var (sz, cz) = MathF.SinCos(az);
        var y1 = p.Y * cx - p.Z * sx; var z1 = p.Y * sx + p.Z * cx;
        var x2 = p.X * cy + z1 * sy; var z2 = -p.X * sy + z1 * cy;
        var x3 = x2 * cz - y1 * sz; var y3 = x2 * sz + y1 * cz;
        return new Vector3(x3, y3, z2);
    }
}

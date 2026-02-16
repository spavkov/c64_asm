using DemoEffectsShowcase.Core;

namespace DemoEffectsShowcase.Effects;

public sealed class CubeTwisterEffect : DemoSceneEffect
{
    private int _width;
    private int _height;
    private double _time;
    private float _speed = 1.0f;
    private float _spinAmount = 1.7f;
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;
    private const float HalfPi = MathF.PI * 0.5f;

    public CubeTwisterEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.2f, 4.0f),
            EffectParameters.Float("spin", "Spin Amount", () => _spinAmount, v => _spinAmount = v, 0.5f, 4.0f)
        ];
    }

    public string Id => "cube-twister";
    public string Name => "Cube Twister";
    public string Description => "Amiga-style twister ribbon/cube illusion.";
    public IReadOnlyList<string> Tags => ["twister", "cube", "ribbon"];
    public void Initialize(in EffectInitContext context) => Resize(context.Width, context.Height);
    public void Resize(int width, int height) { _width = Math.Max(1, width); _height = Math.Max(1, height); }
    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        var centerX = _width / 2f;
        var yStep = 2;
        Span<float> x = stackalloc float[4];
        for (var y = 0; y < _height; y += yStep)
        {
            var yNorm = (y / (float)Math.Max(1, _height - 1)) * 2f - 1f;
            var phase = _spinAmount * MathF.Sin(yNorm * MathF.Cos((float)_time)) + MathF.Cos((float)_time * 0.9f);
            var amp = _width * 0.23f;
            for (var i = 0; i < 4; i++) x[i] = centerX + amp * MathF.Sin(phase + HalfPi * i);
            for (var i = 0; i < 4; i++)
            {
                var n = (i + 1) & 3;
                if (x[n] <= x[i]) continue;
                var shade = (byte)(70 + 180 * (0.5f + 0.5f * MathF.Sin(phase + i)));
                SdlFx.Line(renderer, (int)x[i], y, (int)x[n], y, shade, (byte)(shade * 0.8f), 255);
            }
        }
    }

    public void Dispose() { }
    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;
}

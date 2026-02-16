using DemoEffectsShowcase.Core;

namespace DemoEffectsShowcase.Effects;

public sealed class CopperBarsEffect : DemoSceneEffect
{
    private int _width;
    private int _height;
    private double _time;
    private float _speed = 1.0f;
    private float _glow = 1.0f;
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;

    public CopperBarsEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.1f, 4.0f),
            EffectParameters.Float("glow", "Glow Strength", () => _glow, v => _glow = v, 0.1f, 2.5f)
        ];
    }

    public string Id => "copper-bars";
    public string Name => "Copper Bars";
    public string Description => "Animated horizontal copper-like bars.";
    public IReadOnlyList<string> Tags => ["copper", "bars", "raster"];

    public void Initialize(in EffectInitContext context)
    {
        _width = context.Width;
        _height = context.Height;
        _time = 0;
    }

    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
    }

    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        for (var y = 0; y < _height; y++)
        {
            var fy = y / (float)_height;
            var barWave =
                Math.Sin(fy * 26 + _time * 2.2) +
                Math.Sin(fy * 15 + _time * 1.4) * 0.7 +
                Math.Sin(fy * 7 - _time * 1.8) * 0.5;

            var intensity = (barWave + 2.2) / 4.4;
            var r = (byte)Math.Clamp(40 + intensity * 205, 0, 255);
            var g = (byte)Math.Clamp(20 + intensity * 120, 0, 255);
            var b = (byte)Math.Clamp(30 + intensity * 160, 0, 255);

            SdlFx.Line(renderer, 0, y, _width, y, r, g, b);
        }

        var glowY = (int)((Math.Sin(_time * 2.6) * 0.5 + 0.5) * (_height - 1));
        for (var i = -3; i <= 3; i++)
        {
            var y = glowY + i;
            if (y < 0 || y >= _height)
            {
                continue;
            }

            var brightness = (byte)Math.Clamp((255 - Math.Abs(i) * 30) * _glow, 0, 255);
            SdlFx.Line(renderer, 0, y, _width, y, brightness, brightness, 255);
        }
    }

    public void Dispose()
    {
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

}

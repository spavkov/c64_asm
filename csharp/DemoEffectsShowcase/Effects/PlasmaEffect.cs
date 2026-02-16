using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class PlasmaEffect : DemoSceneEffect
{
    private int _width;
    private int _height;
    private double _time;
    private float _speed = 2.0f;
    private Vector3 _tint = new(1.0f, 1.0f, 1.0f);
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;
    private const int BaseBlock = 6;

    public PlasmaEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.1f, 8.0f),
            EffectParameters.Color3("tint", "Color Tint", () => _tint, v => _tint = v)
        ];
    }

    public string Id => "plasma";
    public string Name => "Plasma";
    public string Description => "Classic sine plasma.";
    public IReadOnlyList<string> Tags => ["plasma", "sine", "color"];

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
        var block = Math.Max(BaseBlock, (int)MathF.Sqrt((_width * _height) / 12000f));

        for (var y = 0; y < _height; y += block)
        {
            for (var x = 0; x < _width; x += block)
            {
                var v1 = Math.Sin(x * 0.03 + _time);
                var v2 = Math.Sin(y * 0.04 + _time * 1.3);
                var v3 = Math.Sin((x + y) * 0.02 + _time * 0.7);
                var value = (v1 + v2 + v3) / 3.0;

                var r = (byte)Math.Clamp((128 + 127 * Math.Sin(value * 4.0 + _time)) * _tint.X, 0, 255);
                var g = (byte)Math.Clamp((128 + 127 * Math.Sin(value * 4.0 + 2.09 + _time * 1.1)) * _tint.Y, 0, 255);
                var b = (byte)Math.Clamp((128 + 127 * Math.Sin(value * 4.0 + 4.18 + _time * 0.9)) * _tint.Z, 0, 255);

                SdlFx.FillRect(renderer, x, y, block, block, r, g, b);
            }
        }
    }

    public void Dispose()
    {
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

}

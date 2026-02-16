using DemoEffectsShowcase.Core;

namespace DemoEffectsShowcase.Effects;

public sealed class FireEffect : DemoSceneEffect
{
    private readonly Random _random = new(77);
    private int _width;
    private int _height;
    private int _gridW;
    private int _gridH;
    private int[,] _heat = new int[1, 1];
    private int _cell = 3;
    private float _intensity = 1.0f;
    private float _cooling = 1.0f;
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;
    private const int BaseCell = 3;

    public FireEffect()
    {
        _parameters =
        [
            EffectParameters.Float("intensity", "Intensity", () => _intensity, v => _intensity = v, 0.2f, 2.5f),
            EffectParameters.Float("cooling", "Cooling", () => _cooling, v => _cooling = v, 0.3f, 2.0f)
        ];
    }

    public string Id => "fire";
    public string Name => "Fire";
    public string Description => "Classic palette fire simulation.";
    public IReadOnlyList<string> Tags => ["fire", "palette", "flame"];

    public void Initialize(in EffectInitContext context) => Resize(context.Width, context.Height);

    public void Resize(int width, int height)
    {
        var newWidth = Math.Max(1, width);
        var newHeight = Math.Max(1, height);
        var newCell = Math.Max(BaseCell, (int)MathF.Sqrt((newWidth * newHeight) / 12000f));
        if (newWidth == _width && newHeight == _height && newCell == _cell)
        {
            return;
        }

        _width = newWidth;
        _height = newHeight;
        _cell = newCell;
        _gridW = Math.Max(8, _width / _cell);
        _gridH = Math.Max(8, _height / _cell);
        _heat = new int[_gridW, _gridH];
    }

    public void Update(double deltaSeconds)
    {
        for (var x = 0; x < _gridW; x++)
        {
            _heat[x, _gridH - 1] = Math.Clamp((int)((180 + _random.Next(75)) * _intensity), 0, 255);
        }

        for (var y = _gridH - 2; y >= 0; y--)
        {
            for (var x = 0; x < _gridW; x++)
            {
                var below = _heat[x, y + 1];
                var left = _heat[Math.Max(0, x - 1), y + 1];
                var right = _heat[Math.Min(_gridW - 1, x + 1), y + 1];
                var decay = (int)Math.Clamp(_random.Next(0, 5) * _cooling, 0, 16);
                _heat[x, y] = Math.Max(0, (below + left + right) / 3 - decay);
            }
        }
    }

    public void Render(IntPtr renderer)
    {
        for (var y = 0; y < _gridH; y++)
        {
            for (var x = 0; x < _gridW; x++)
            {
                var val = _heat[x, y];
                var (r, g, b) = FireColor(val);
                SdlFx.FillRect(renderer, x * _cell, y * _cell, _cell + 1, _cell + 1, r, g, b);
            }
        }
    }

    public void Dispose()
    {
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

    private static (byte r, byte g, byte b) FireColor(int v)
    {
        var value = Math.Clamp(v, 0, 255);
        byte r;
        byte g;
        byte b;

        if (value < 85)
        {
            r = (byte)(value * 3);
            g = 0;
            b = 0;
        }
        else if (value < 170)
        {
            r = 255;
            g = (byte)((value - 85) * 3);
            b = 0;
        }
        else
        {
            r = 255;
            g = 255;
            b = (byte)((value - 170) * 3);
        }

        return (r, g, b);
    }
}

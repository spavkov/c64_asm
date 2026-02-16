using DemoEffectsShowcase.Core;

namespace DemoEffectsShowcase.Effects;

public sealed class RotozoomEffect : DemoSceneEffect
{
    private int _width;
    private int _height;
    private double _time;
    private float _speed = 1.0f;
    private float _zoomAmount = 0.6f;
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;
    private const int BaseStep = 5;

    public RotozoomEffect()
    {
        _parameters =
        [
            EffectParameters.Float("speed", "Speed", () => _speed, v => _speed = v, 0.2f, 3.0f),
            EffectParameters.Float("zoom", "Zoom Amount", () => _zoomAmount, v => _zoomAmount = v, 0.1f, 1.4f)
        ];
    }

    public string Id => "rotozoom";
    public string Name => "Rotozoom";
    public string Description => "Rotating and zooming checkerboard texture.";
    public IReadOnlyList<string> Tags => ["rotozoom", "rotation", "zoom"];

    public void Initialize(in EffectInitContext context) => Resize(context.Width, context.Height);
    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
    }

    public void Update(double deltaSeconds) => _time += deltaSeconds * _speed;

    public void Render(IntPtr renderer)
    {
        var cx = _width * 0.5f;
        var cy = _height * 0.5f;
        var angle = (float)_time * 0.9f;
        var s = MathF.Sin(angle);
        var c = MathF.Cos(angle);
        var zoom = 1.2f + MathF.Sin((float)_time * 1.5f) * _zoomAmount;
        var step = Math.Max(BaseStep, (int)MathF.Sqrt((_width * _height) / 12000f));

        for (var y = 0; y < _height; y += step)
        {
            for (var x = 0; x < _width; x += step)
            {
                var nx = (x - cx) / cx;
                var ny = (y - cy) / cy;
                var rx = (nx * c - ny * s) * zoom;
                var ry = (nx * s + ny * c) * zoom;

                var tileX = ((int)MathF.Floor((rx + 100f) * 10f)) & 1;
                var tileY = ((int)MathF.Floor((ry + 100f) * 10f)) & 1;
                var checker = tileX ^ tileY;
                var pulse = 0.5f + 0.5f * MathF.Sin((rx + ry) * 5f + (float)_time * 3f);

                var baseColor = checker == 0 ? 60 : 170;
                var val = (byte)Math.Clamp(baseColor + pulse * 70f, 0f, 255f);
                SdlFx.FillRect(renderer, x, y, step, step, val, (byte)(val * 0.8f), (byte)(220 - val / 2));
            }
        }
    }

    public void Dispose()
    {
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

}

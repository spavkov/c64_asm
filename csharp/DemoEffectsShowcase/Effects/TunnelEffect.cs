using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class TunnelEffect : DemoSceneEffect
{
    private int _width;
    private int _height;
    private double _time;
    private float _forwardSpeed = 1.0f;
    private float _rotationSpeed = 0.25f;
    private float _ratio = 32.0f;
    private Vector3 _color = new(1f, 1f, 1f);
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;
    private const int BaseStep = 4;
    private const int TexWidth = 256;
    private const int TexHeight = 256;
    private int[] _distanceTable = [];
    private int[] _angleTable = [];
    private byte[] _texture = [];

    public TunnelEffect()
    {
        BuildTexture();
        _parameters =
        [
            EffectParameters.Float("forward", "Forward Speed", () => _forwardSpeed, v => _forwardSpeed = v, 0.1f, 3.0f),
            EffectParameters.Float("rotation", "Rotation Speed", () => _rotationSpeed, v => _rotationSpeed = v, -2.0f, 2.0f),
            EffectParameters.Float("ratio", "Depth Ratio", () => _ratio, v => _ratio = v, 8.0f, 64.0f),
            EffectParameters.Color3("tint", "Color Tint", () => _color, v => _color = v)
        ];
    }

    public string Id => "tunnel";
    public string Name => "Tunnel";
    public string Description => "Forward-moving tunnel illusion.";
    public IReadOnlyList<string> Tags => ["tunnel", "polar", "depth"];

    public void Initialize(in EffectInitContext context) => Resize(context.Width, context.Height);
    public void Resize(int width, int height)
    {
        _width = Math.Max(1, width);
        _height = Math.Max(1, height);
        BuildTables();
    }

    public void Update(double deltaSeconds) => _time += deltaSeconds;

    public void Render(IntPtr renderer)
    {
        var shiftX = (int)(TexWidth * _forwardSpeed * _time);
        var shiftY = (int)(TexHeight * _rotationSpeed * _time);
        var step = Math.Max(BaseStep, (int)MathF.Sqrt((_width * _height) / 12000f));
        for (var y = 0; y < _height; y += step)
        {
            for (var x = 0; x < _width; x += step)
            {
                var idx = y * _width + x;
                var texX = (_distanceTable[idx] + shiftX) & (TexWidth - 1);
                var texY = (_angleTable[idx] + shiftY) & (TexHeight - 1);
                var sample = _texture[texY * TexWidth + texX];
                var intensity = sample / 255f;

                var r = (byte)Math.Clamp((25 + intensity * 120) * _color.X, 0, 255);
                var g = (byte)Math.Clamp((20 + intensity * 100) * _color.Y, 0, 255);
                var b = (byte)Math.Clamp((50 + intensity * 180) * _color.Z, 0, 255);
                SdlFx.FillRect(renderer, x, y, step, step, r, g, b);
            }
        }
    }

    public void Dispose()
    {
    }

    public IReadOnlyList<EffectParameterDefinition> GetParameters() => _parameters;

    private void BuildTexture()
    {
        _texture = new byte[TexWidth * TexHeight];
        for (var y = 0; y < TexHeight; y++)
        {
            for (var x = 0; x < TexWidth; x++)
            {
                _texture[y * TexWidth + x] = (byte)((x * 255 / TexWidth) ^ (y * 255 / TexHeight));
            }
        }
    }

    private void BuildTables()
    {
        _distanceTable = new int[_width * _height];
        _angleTable = new int[_width * _height];
        var cx = _width / 2.0f;
        var cy = _height / 2.0f;

        for (var y = 0; y < _height; y++)
        {
            for (var x = 0; x < _width; x++)
            {
                var dx = x - cx;
                var dy = y - cy;
                var d = MathF.Sqrt(dx * dx + dy * dy);
                if (d < 1f)
                {
                    d = 1f;
                }

                var distance = (int)(_ratio * TexHeight / d) % TexHeight;
                var angle = (int)(0.5f * TexWidth * MathF.Atan2(dy, dx) / MathF.PI);
                var idx = y * _width + x;
                _distanceTable[idx] = distance;
                _angleTable[idx] = angle;
            }
        }
    }

}

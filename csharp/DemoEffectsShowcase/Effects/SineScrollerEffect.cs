using DemoEffectsShowcase.Core;

namespace DemoEffectsShowcase.Effects;

public sealed class SineScrollerEffect : DemoSceneEffect
{
    private const string ScrollText = "...  DEMO EFFECTS SHOWCASE  SINE SCROLLER ...                                           ";
    private const int GlyphScale = 2;
    private int _w,_h; private double _t; private float _speed=95f,_amp=35f;
    private readonly IReadOnlyList<EffectParameterDefinition> _params;
    public SineScrollerEffect(){_params=[EffectParameters.Float("speed","Scroll Speed",()=>_speed,v=>_speed=v,20f,220f),EffectParameters.Float("amplitude","Wave Amplitude",()=>_amp,v=>_amp=v,5f,70f)];}
    public string Id=>"sine-scroller"; public string Name=>"Sine Scroller"; public string Description=>"Sine-wave scrolling text."; public IReadOnlyList<string> Tags=>["sine","scroller","text"];
    public void Initialize(in EffectInitContext c)=>Resize(c.Width,c.Height); public void Resize(int w,int h){_w=Math.Max(1,w);_h=Math.Max(1,h);} public void Update(double d)=>_t+=d;
    public void Render(IntPtr renderer)
    {
        var advance = 6 * GlyphScale;
        var total = ScrollText.Length * advance;
        var scroll = (float)(_t * _speed % total);
        var baseY = _h / 2 - (7 * GlyphScale) / 2;
        var firstX = (int)(_w - scroll);
        for (var textStart = firstX - total; textStart < _w + total; textStart += total)
        for (var i = 0; i < ScrollText.Length; i++)
        {
            var x = textStart + i * advance;
            if (x < -advance || x > _w) continue;
            var y = (int)(baseY + MathF.Sin((float)_t * 4f + i * 0.45f) * _amp);
            var c = (byte)(120 + 120 * MathF.Sin((float)_t * 2f + i * 0.2f));
            SdlText.Draw(renderer, ScrollText[i].ToString(), x, y, GlyphScale, c, (byte)(c * 0.8f), 255);
        }
    }
    public void Dispose(){} public IReadOnlyList<EffectParameterDefinition> GetParameters()=>_params;
}

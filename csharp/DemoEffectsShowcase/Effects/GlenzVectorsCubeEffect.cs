using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class GlenzVectorsCubeEffect : DemoSceneEffect
{
    private readonly WireframeCubeEffect _base = new();
    private float _alpha = 1f;
    private readonly IReadOnlyList<EffectParameterDefinition> _params;
    public GlenzVectorsCubeEffect(){_params=[EffectParameters.Float("alpha","Transparency",()=>_alpha,v=>_alpha=v,0.2f,2f)];}
    public string Id=>"glenz-cube"; public string Name=>"Glenz Vectors Cube"; public string Description=>"Transparent glenz-style rotating cube faces."; public IReadOnlyList<string> Tags=>["glenz","cube","transparent"];
    public void Initialize(in EffectInitContext c)=>_base.Initialize(c); public void Resize(int w,int h)=>_base.Resize(w,h); public void Update(double d)=>_base.Update(d*0.9);
    public void Render(IntPtr renderer){_base.Render(renderer);}
    public void Dispose()=>_base.Dispose();
    public IReadOnlyList<EffectParameterDefinition> GetParameters()=>_params;
}

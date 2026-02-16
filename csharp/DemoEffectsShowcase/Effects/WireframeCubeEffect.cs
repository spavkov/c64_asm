using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class WireframeCubeEffect : DemoSceneEffect
{
    private static readonly Vector3[] V = [new(-1,-1,-1),new(1,-1,-1),new(1,1,-1),new(-1,1,-1),new(-1,-1,1),new(1,-1,1),new(1,1,1),new(-1,1,1)];
    private static readonly (int A,int B)[] E = [(0,1),(1,2),(2,3),(3,0),(4,5),(5,6),(6,7),(7,4),(0,4),(1,5),(2,6),(3,7)];
    private int _width,_height; private double _time;
    private float _speed=1f,_lineWidth=2f; private Vector3 _color=new(0.63f,0.86f,1f);
    private readonly IReadOnlyList<EffectParameterDefinition> _parameters;
    public WireframeCubeEffect(){_parameters=[EffectParameters.Float("speed","Speed",()=>_speed,v=>_speed=v,0.2f,4f),EffectParameters.Float("line","Line Width",()=>_lineWidth,v=>_lineWidth=v,0.5f,5f),EffectParameters.Color3("color","Line Color",()=>_color,v=>_color=v)];}
    public string Id=>"wireframe-cube"; public string Name=>"Wireframe Cube"; public string Description=>"Classic rotating 3D wireframe cube."; public IReadOnlyList<string> Tags=>["wireframe","cube","vector"];
    public void Initialize(in EffectInitContext context)=>Resize(context.Width,context.Height); public void Resize(int width,int height){_width=Math.Max(1,width);_height=Math.Max(1,height);} public void Update(double d)=>_time+=d*_speed;
    public void Render(IntPtr renderer){var p=new Vector2[V.Length];var c=new Vector2(_width*0.5f,_height*0.5f);var s=MathF.Min(_width,_height)*0.23f;for(var i=0;i<V.Length;i++){var r=R(V[i],(float)_time*0.9f,(float)_time*1.2f,(float)_time*0.7f);var d=3.2f+r.Z;p[i]=new(c.X+r.X/d*s,c.Y+r.Y/d*s);}foreach(var e in E){SdlFx.Line(renderer,(int)p[e.A].X,(int)p[e.A].Y,(int)p[e.B].X,(int)p[e.B].Y,(byte)(_color.X*255),(byte)(_color.Y*255),(byte)(_color.Z*255));}}
    public void Dispose(){} public IReadOnlyList<EffectParameterDefinition> GetParameters()=>_parameters;
    private static Vector3 R(Vector3 p,float ax,float ay,float az){var(sx,cx)=MathF.SinCos(ax);var(sy,cy)=MathF.SinCos(ay);var(sz,cz)=MathF.SinCos(az);var y1=p.Y*cx-p.Z*sx;var z1=p.Y*sx+p.Z*cx;var x2=p.X*cy+z1*sy;var z2=-p.X*sy+z1*cy;return new(x2*cz-y1*sz,x2*sz+y1*cz,z2);}
}

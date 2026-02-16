using DemoEffectsShowcase.Core;
using System.Numerics;

namespace DemoEffectsShowcase.Effects;

public sealed class CubePlasmaSideEffect : DemoSceneEffect
{
    private static readonly Vector3[] V = [new(-1,-1,-1),new(1,-1,-1),new(1,1,-1),new(-1,1,-1),new(-1,-1,1),new(1,-1,1),new(1,1,1),new(-1,1,1)];
    private static readonly int[][] Faces = [[0,1,2,3],[4,5,6,7],[0,3,7,4],[1,2,6,5],[0,1,5,4],[3,2,6,7]];
    private readonly WireframeCubeEffect _cube = new();
    private int _w,_h; private double _t,_rot; private float _speed=1f,_plasma=1f;
    private readonly IReadOnlyList<EffectParameterDefinition> _params;
    public CubePlasmaSideEffect(){_params=[EffectParameters.Float("speed","Rotation Speed",()=>_speed,v=>_speed=v,0.2f,3f),EffectParameters.Float("plasma","Plasma Speed",()=>_plasma,v=>_plasma=v,0.2f,3f)];}
    public string Id=>"cube-plasma-side"; public string Name=>"Cube + Plasma Side"; public string Description=>"Rotating cube with one plasma face."; public IReadOnlyList<string> Tags=>["cube","plasma","hybrid"];
    public void Initialize(in EffectInitContext c){Resize(c.Width,c.Height);_cube.Initialize(c);} public void Resize(int w,int h){_w=Math.Max(1,w);_h=Math.Max(1,h);_cube.Resize(w,h);} public void Update(double d){_t+=d*_speed;_rot+=d*_speed;_cube.Update(d*_speed);}
    public void Render(IntPtr renderer)
    {
        var c=new Vector2(_w*0.5f,_h*0.5f);var s=MathF.Min(_w,_h)*0.23f;var p=new Vector2[V.Length];
        for(var i=0;i<V.Length;i++){var r=R(V[i],(float)_rot*0.9f,(float)_rot*1.2f,(float)_rot*0.7f);var d=3.2f+r.Z;p[i]=new(c.X+r.X/d*s,c.Y+r.Y/d*s);}
        var face=Faces[3];
        DrawPlasmaFace(renderer,p[face[0]],p[face[1]],p[face[2]],p[face[3]]);
        _cube.Render(renderer);
    }
    public void Dispose()=>_cube.Dispose(); public IReadOnlyList<EffectParameterDefinition> GetParameters()=>_params;
    private void DrawPlasmaFace(IntPtr renderer,Vector2 a,Vector2 b,Vector2 c,Vector2 d)
    {
        var minX=(int)MathF.Floor(MathF.Min(MathF.Min(a.X,b.X),MathF.Min(c.X,d.X)));var maxX=(int)MathF.Ceiling(MathF.Max(MathF.Max(a.X,b.X),MathF.Max(c.X,d.X)));
        var minY=(int)MathF.Floor(MathF.Min(MathF.Min(a.Y,b.Y),MathF.Min(c.Y,d.Y)));var maxY=(int)MathF.Ceiling(MathF.Max(MathF.Max(a.Y,b.Y),MathF.Max(c.Y,d.Y)));
        minX=Math.Clamp(minX,0,_w-1);maxX=Math.Clamp(maxX,0,_w-1);minY=Math.Clamp(minY,0,_h-1);maxY=Math.Clamp(maxY,0,_h-1);
        for(var y=minY;y<=maxY;y+=4)for(var x=minX;x<=maxX;x+=4)
        {
            var p=new Vector2(x+2f,y+2f);if(!Uv(a,b,c,d,p,out var u,out var v))continue;
            var n=(Math.Sin((u*160+_t*100*_plasma)*0.03)+Math.Sin((v*160+_t*80*_plasma)*0.04))*0.5+0.5;
            var r=(byte)(120+n*120);var g=(byte)(70+n*100);var bl=(byte)(170+n*80);SdlFx.FillRect(renderer,x,y,4,4,r,g,bl);
        }
    }
    private static bool Uv(Vector2 a,Vector2 b,Vector2 c,Vector2 d,Vector2 p,out float u,out float v)
    {
        if(Bary(a,b,c,p,out var w1,out var w2,out var w3)){u=w2+w3;v=w3;return true;}
        if(Bary(a,c,d,p,out w1,out w2,out w3)){u=w2;v=w2+w3;return true;}
        u=v=0;return false;
    }
    private static bool Bary(Vector2 a,Vector2 b,Vector2 c,Vector2 p,out float w1,out float w2,out float w3)
    {
        var den=((b.Y-c.Y)*(a.X-c.X)+(c.X-b.X)*(a.Y-c.Y));if(MathF.Abs(den)<0.0001f){w1=w2=w3=0;return false;}
        w1=((b.Y-c.Y)*(p.X-c.X)+(c.X-b.X)*(p.Y-c.Y))/den;w2=((c.Y-a.Y)*(p.X-c.X)+(a.X-c.X)*(p.Y-c.Y))/den;w3=1f-w1-w2;
        return w1>=0f&&w2>=0f&&w3>=0f;
    }
    private static Vector3 R(Vector3 p,float ax,float ay,float az){var(sx,cx)=MathF.SinCos(ax);var(sy,cy)=MathF.SinCos(ay);var(sz,cz)=MathF.SinCos(az);var y1=p.Y*cx-p.Z*sx;var z1=p.Y*sx+p.Z*cx;var x2=p.X*cy+z1*sy;var z2=-p.X*sy+z1*cy;return new(x2*cz-y1*sz,x2*sz+y1*cz,z2);}
}

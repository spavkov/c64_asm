using DemoEffectsShowcase.Core;
using System.Numerics;
using System.Drawing;

namespace DemoEffectsShowcase.Effects;

public sealed class TexturedCubeEffect : DemoSceneEffect
{
    private static readonly Vector3[] V = [new(-1,-1,-1),new(1,-1,-1),new(1,1,-1),new(-1,1,-1),new(-1,-1,1),new(1,-1,1),new(1,1,1),new(-1,1,1)];
    private static readonly int[][] Faces = [[0,1,2,3],[5,4,7,6],[4,0,3,7],[1,5,6,2],[4,5,1,0],[3,2,6,7]];
    private int _width,_height; private double _time; private float _speed=1f,_density=7f,_zoom=1f;
    private readonly byte[] _texture;
    private readonly int _textureWidth;
    private readonly int _textureHeight;
    private readonly IReadOnlyList<EffectParameterDefinition> _params;
    public TexturedCubeEffect(){(_textureWidth,_textureHeight,_texture)=LoadTexture();_params=[EffectParameters.Float("speed","Speed",()=>_speed,v=>_speed=v,0.2f,3f),EffectParameters.Float("density","Texture Density",()=>_density,v=>_density=v,3f,16f),EffectParameters.Float("zoom","Zoom",()=>_zoom,v=>_zoom=v,0.6f,2.2f)];}
    public string Id=>"textured-cube"; public string Name=>"Textured Cube"; public string Description=>"Rotating cube textured on all faces."; public IReadOnlyList<string> Tags=>["cube","texture","mapped"];
    public void Initialize(in EffectInitContext c)=>Resize(c.Width,c.Height); public void Resize(int w,int h){_width=Math.Max(1,w);_height=Math.Max(1,h);} public void Update(double d)=>_time+=d*_speed;
    public void Render(IntPtr renderer)
    {
        var center=new Vector2(_width*0.5f,_height*0.5f);var zoom=Math.Clamp(_zoom,0.6f,2.2f);var size=MathF.Min(_width,_height)*0.23f*zoom;var a=(float)_time;var cameraDistance=3.2f;
        var projected=new Vector2[V.Length];var rotated=new Vector3[V.Length];
        for(var i=0;i<V.Length;i++){var r=R(V[i],a*0.9f,a*1.2f,a*0.7f);rotated[i]=r;var d=MathF.Max(0.25f,cameraDistance+r.Z);projected[i]=new(center.X+r.X/d*size,center.Y+r.Y/d*size);}
        var cameraPos=new Vector3(0f,0f,-cameraDistance);
        var faceOrder=Enumerable.Range(0,Faces.Length)
            .Where(i=>{var f=Faces[i];var a3=rotated[f[0]];var b3=rotated[f[1]];var c3=rotated[f[2]];var d3=rotated[f[3]];var n=Vector3.Cross(b3-a3,c3-a3);var center3=(a3+b3+c3+d3)*0.25f;return Vector3.Dot(n,cameraPos-center3)<0f;})
            .OrderByDescending(i=>(rotated[Faces[i][0]].Z+rotated[Faces[i][1]].Z+rotated[Faces[i][2]].Z+rotated[Faces[i][3]].Z)*0.25f);
        var step=Math.Max(1,18/Math.Clamp((int)_density,3,16));
        foreach(var fi in faceOrder){var f=Faces[fi];var a0=projected[f[0]];var b0=projected[f[1]];var c0=projected[f[2]];var d0=projected[f[3]];DrawTexturedFace(renderer,a0,b0,c0,d0,step);DrawFaceOutline(renderer,a0,b0,c0,d0);}
    }
    public void Dispose(){} public IReadOnlyList<EffectParameterDefinition> GetParameters()=>_params;
    private void DrawTexturedFace(IntPtr renderer,Vector2 a,Vector2 b,Vector2 c,Vector2 d,int step)
    {
        var minX=(int)MathF.Floor(MathF.Min(MathF.Min(a.X,b.X),MathF.Min(c.X,d.X)));var maxX=(int)MathF.Ceiling(MathF.Max(MathF.Max(a.X,b.X),MathF.Max(c.X,d.X)));
        var minY=(int)MathF.Floor(MathF.Min(MathF.Min(a.Y,b.Y),MathF.Min(c.Y,d.Y)));var maxY=(int)MathF.Ceiling(MathF.Max(MathF.Max(a.Y,b.Y),MathF.Max(c.Y,d.Y)));
        minX=Math.Clamp(minX,0,_width-1);maxX=Math.Clamp(maxX,0,_width-1);minY=Math.Clamp(minY,0,_height-1);maxY=Math.Clamp(maxY,0,_height-1);
        for(var y=minY;y<=maxY;y+=step)for(var x=minX;x<=maxX;x+=step)
        {
            var p=new Vector2(x+step*0.5f,y+step*0.5f);if(!Uv(a,b,c,d,p,out var u,out var v))continue;
            var tx=Math.Clamp((int)(u*(_textureWidth-1)),0,_textureWidth-1);var ty=Math.Clamp((int)(v*(_textureHeight-1)),0,_textureHeight-1);
            var i=(ty*_textureWidth+tx)*3;SdlFx.FillRect(renderer,x,y,step,step,_texture[i],_texture[i+1],_texture[i+2]);
        }
    }
    private static void DrawFaceOutline(IntPtr renderer,Vector2 a,Vector2 b,Vector2 c,Vector2 d)
    {
        const byte edge=28;
        SdlFx.Line(renderer,(int)a.X,(int)a.Y,(int)b.X,(int)b.Y,edge,edge,edge);
        SdlFx.Line(renderer,(int)b.X,(int)b.Y,(int)c.X,(int)c.Y,edge,edge,edge);
        SdlFx.Line(renderer,(int)c.X,(int)c.Y,(int)d.X,(int)d.Y,edge,edge,edge);
        SdlFx.Line(renderer,(int)d.X,(int)d.Y,(int)a.X,(int)a.Y,edge,edge,edge);
    }
    private static (int Width,int Height,byte[] Data) LoadTexture()
    {
        var texturePath=Path.Combine(AppContext.BaseDirectory,"textures","tunnelstonetex.png");
        if(!File.Exists(texturePath))throw new InvalidOperationException($"Missing texture file: {texturePath}");
        using var bitmap=new Bitmap(texturePath);
        var width=bitmap.Width;var height=bitmap.Height;var data=new byte[width*height*3];
        for(var y=0;y<height;y++)for(var x=0;x<width;x++){var c=bitmap.GetPixel(x,y);var i=(y*width+x)*3;data[i]=c.R;data[i+1]=c.G;data[i+2]=c.B;}
        return (width,height,data);
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

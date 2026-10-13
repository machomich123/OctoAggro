// Exact-client rendering bridge. No targeting, casting, movement or packets.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <bcrypt.h>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <unordered_map>
#include "vendor/minhook/include/MinHook.h"

namespace {
using L=void*;
using CFn=int(__fastcall*)(L);
using Register=void(__fastcall*)(const char*,CFn);
using Tick=void(__fastcall*)(int,int,int);
template<class T> T at(uintptr_t a){return reinterpret_cast<T>(a);}
auto context=at<L(__fastcall*)()>(0x7040D0);
auto type=at<int(__fastcall*)(L,int)>(0x6F3400);
auto number=at<double(__fastcall*)(L,int)>(0x6F3620);
auto string=at<const char*(__fastcall*)(L,int)>(0x6F3690);
auto boolean=at<int(__fastcall*)(L,int)>(0x6F3660);
auto settop=at<void(__fastcall*)(L,int)>(0x6F3080);
auto pushnumber=at<void(__fastcall*)(L,double)>(0x6F3810);
auto pushnil=at<void(__fastcall*)(L)>(0x6F37F0);
Register registerOriginal=nullptr;
Tick tickOriginal=nullptr;
bool registering=false,loaded=false;
constexpr int reason=30; // Own rendering reason; leave native reasons intact.
std::unordered_map<uint64_t,DWORD> owned;
struct V {float x,y,z;};
bool ready(){return *at<void**>(0xB41414)!=nullptr;}
void* object(uint64_t guid){
  if(!ready() || !guid)return nullptr;
  using Fn=void*(__fastcall*)(int,const char*,uint32_t,uint32_t,int);
  return at<Fn>(0x468460)(8,"OctoAggro",static_cast<uint32_t>(guid),static_cast<uint32_t>(guid>>32),0);
}
bool parse(const char* s,uint64_t& out){
  if(!s || std::strlen(s)!=18 || s[0]!='0' || (s[1]!='x' && s[1]!='X'))return false;
  out=0;
  for(int i=2;i<18;i++){
    unsigned v=s[i]>='0' && s[i]<='9' ? s[i]-'0' : s[i]>='a' && s[i]<='f' ? s[i]-'a'+10 : s[i]>='A' && s[i]<='F' ? s[i]-'A'+10 : 99;
    if(v>15)return false; out=(out<<4)|v;
  }return out!=0;
}
void glow(void* obj,bool enable){
  // Both native CGObject methods were traced from the actual mouseover setter.
  if(!obj)return;
  uintptr_t addr=enable?0x614550:0x6144F0;
  at<void(__thiscall*)(void*,int)>(addr)(obj,reason);
}
void clear(){for(const auto& entry:owned)glow(object(entry.first),false);owned.clear();}
bool vector(L l,int first,V& v){
  double values[3];
  for(int i=0;i<3;i++){
    if(type(l,first+i)!=3)return false;
    values[i]=number(l,first+i);
    if(!std::isfinite(values[i]) || std::abs(values[i])>50000)return false;
  }v={static_cast<float>(values[0]),static_cast<float>(values[1]),static_cast<float>(values[2])};return true;
}
int missing(L l){settop(l,0);pushnil(l);return 1;}
bool trace(const V& a,const V& b,V& hit,float& t){
  using Fn=char(__fastcall*)(const V*,const V*,int,V*,float*,uint32_t);
  return at<Fn>(0x672170)(&a,&b,0,&hit,&t,0x100111)!=0;
}
bool sight(const V& point){
  uintptr_t cam=at<uintptr_t(__fastcall*)()>(0x4818F0)();
  if(!cam)return false;
  V start=*reinterpret_cast<V*>(cam+8);
  float dx=start.x-point.x,dy=start.y-point.y,dz=start.z-point.z;
  float d=std::sqrt(dx*dx+dy*dy+dz*dz);
  if(!std::isfinite(d) || d>150)return false;
  if(d<0.1f)return true;
  V hit{};float t=1;
  return !trace(start,point,hit,t) || (t>=0.998f && t<=1.0f);
}
int __fastcall Version(L){L l=context();settop(l,0);pushnumber(l,1);return 1;}
int __fastcall Clear(L){L l=context();clear();settop(l,0);pushnumber(l,1);return 1;}
int __fastcall Glow(L){
  L l=context();uint64_t guid=0;
  if(type(l,1)!=4 || type(l,2)!=1 || !parse(string(l,1),guid))return missing(l);
  bool enable=boolean(l,2)!=0;
  if(enable && owned.size()>=128 && owned.find(guid)==owned.end())return missing(l);
  void* obj=object(guid);
  if(!obj){owned.erase(guid);return missing(l);}
  glow(obj,enable);
  if(enable)owned[guid]=GetTickCount()+750;else owned.erase(guid);
  settop(l,0);pushnumber(l,1);return 1;
}
int __fastcall Surface(L){
  L l=context();V p{};
  if(!ready() || !vector(l,1,p))return missing(l);
  V a=p,b=p,hit{};a.z+=12;b.z-=24;float t=1;
  if(!trace(a,b,hit,t) || t<0 || t>1 || !std::isfinite(hit.z))return missing(l);
  settop(l,0);pushnumber(l,hit.z+0.08f);return 1;
}
int __fastcall Project(L){
  L l=context();V p{};
  if(!ready() || !vector(l,1,p))return missing(l);
  if(type(l,4)==1 && boolean(l,4) && !sight(p))return missing(l);
  uintptr_t frame=*at<uintptr_t*>(0xB4B2BC);
  if(!frame)return missing(l);
  V ddc{};
  using Fn=bool(__thiscall*)(uintptr_t,float*,float*);
  if(!at<Fn>(0x483EE0)(frame,&p.x,&ddc.x))return missing(l);
  float x=0,y=0;
  at<void(__fastcall*)(float*,float*,float,float)>(0x41ADE0)(&x,&y,ddc.x,ddc.y);
  x+=*reinterpret_cast<float*>(frame+0x3A4);
  y+=*reinterpret_cast<float*>(frame+0x3A0);
  if(!std::isfinite(x)||!std::isfinite(y)||x<0||x>1||y<0||y>1)return missing(l);
  settop(l,0);pushnumber(l,x);pushnumber(l,y);return 2;
}
void __fastcall RegisterHook(const char* name,CFn function){
  registerOriginal(name,function);
  if(!registering && name && !std::strcmp(name,"UnitXP")){
    registering=true;clear();
    registerOriginal("OctoAggroNativeVersion",Version);
    registerOriginal("OctoAggroNativeGlow",Glow);
    registerOriginal("OctoAggroNativeClear",Clear);
    registerOriginal("OctoAggroNativeSurface",Surface);
    registerOriginal("OctoAggroNativeProject",Project);
    registering=false;
  }
}
void __fastcall TickHook(int a,int b,int c){
  tickOriginal(a,b,c);
  DWORD now=GetTickCount();
  for(auto it=owned.begin();it!=owned.end();){
    if(!ready() || static_cast<int32_t>(now-it->second)>=0){glow(object(it->first),false);it=owned.erase(it);}
    else ++it;
  }
}
bool fingerprint(){
  wchar_t path[MAX_PATH];if(!GetModuleFileNameW(nullptr,path,MAX_PATH))return false;
  HANDLE f=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,nullptr,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,nullptr);
  if(f==INVALID_HANDLE_VALUE)return false;
  BCRYPT_ALG_HANDLE alg=nullptr;BCRYPT_HASH_HANDLE hash=nullptr;
  bool ok=BCryptOpenAlgorithmProvider(&alg,BCRYPT_SHA256_ALGORITHM,nullptr,0)>=0;
  if(ok)ok=BCryptCreateHash(alg,&hash,nullptr,0,nullptr,0,0)>=0;
  unsigned char buf[65536];DWORD n=0;
  while(ok){if(!ReadFile(f,buf,sizeof(buf),&n,nullptr)){ok=false;break;}if(!n)break;ok=BCryptHashData(hash,buf,n,0)>=0;}
  unsigned char value[32];if(ok)ok=BCryptFinishHash(hash,value,32,0)>=0;
  constexpr unsigned char expected[32]={0x50,0x14,0xca,0x1c,0xfe,0xdf,0x86,0x0f,0x10,0xe9,0x3f,0xe7,0xd9,0x55,0xc5,0x6c,0x28,0xeb,0x11,0xa2,0xbb,0x50,0x30,0x30,0xdb,0xb9,0xb1,0xc7,0x77,0xf0,0x04,0x70};
  if(ok)ok=std::memcmp(value,expected,32)==0;
  if(hash)BCryptDestroyHash(hash);if(alg)BCryptCloseAlgorithmProvider(alg,0);CloseHandle(f);return ok;
}
}
extern "C" __declspec(dllexport) unsigned __cdecl Load(){
  if(loaded)return 0;
  if(GetModuleHandleW(nullptr)!=reinterpret_cast<HMODULE>(0x400000) || !fingerprint())return 1;
  if(MH_Initialize()!=MH_OK)return 2;
  if(MH_CreateHook(at<void*>(0x704120),reinterpret_cast<void*>(RegisterHook),reinterpret_cast<void**>(&registerOriginal))!=MH_OK)return 3;
  if(MH_CreateHook(at<void*>(0x66FD50),reinterpret_cast<void*>(TickHook),reinterpret_cast<void**>(&tickOriginal))!=MH_OK){MH_RemoveHook(at<void*>(0x704120));return 4;}
  MH_QueueEnableHook(at<void*>(0x704120));MH_QueueEnableHook(at<void*>(0x66FD50));
  if(MH_ApplyQueued()!=MH_OK){MH_DisableHook(MH_ALL_HOOKS);MH_RemoveHook(MH_ALL_HOOKS);return 5;}
  loaded=true;return 0;
}
BOOL WINAPI DllMain(HINSTANCE h,DWORD why,LPVOID){if(why==DLL_PROCESS_ATTACH)DisableThreadLibraryCalls(h);return TRUE;}

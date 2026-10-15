// Exact-client rendering bridge. No targeting, casting, movement or packets.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <bcrypt.h>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <cstdio>
#include <intrin.h>
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
// Separate local render requests, never the server's eight-slot raid table.
std::unordered_map<uint64_t,DWORD> markers;
using RaidIndex=int(__stdcall*)(uint32_t,uint32_t);
RaidIndex raidIndexOriginal=nullptr;
int LocalMarkerIndex(uint64_t guid,int original,uintptr_t caller,DWORD now){
  // Only native world-marker drawing, including its near-range nameplate variant.
  // UI/API callers and existing real raid marks always retain their value.
  if(original!=8 || (caller!=0x6C70A7 && caller!=0x7CB834 && caller!=0x608AAC))return original;
  auto it=markers.find(guid);
  if(it==markers.end() || static_cast<int32_t>(now-it->second)>=0)return original;
  return 7; // Native skull cell, zero-based.
}
int __stdcall RaidIndexHook(uint32_t low,uint32_t high){
  const uintptr_t caller=reinterpret_cast<uintptr_t>(_ReturnAddress());
  int original=raidIndexOriginal(low,high);
  return LocalMarkerIndex((static_cast<uint64_t>(high)<<32)|low,original,caller,GetTickCount());
}
struct RadiusRequest {float radius;DWORD until;};
std::unordered_map<uint64_t,RadiusRequest> circles;
using DrawCircle=void(__thiscall*)(void*);
DrawCircle circleOriginal=nullptr;
using VisualUpdate=void(__thiscall*)(void*,float);
VisualUpdate visualOriginal=nullptr;
bool alwaysCircles=false;
DWORD alwaysUntil=0;
// Change only the ring input, and only during its native draw call.
struct RestoreFloat {
  float* slot;uint32_t bits;
  explicit RestoreFloat(float* p):slot(p){std::memcpy(&bits,p,4);}
  ~RestoreFloat(){std::memcpy(slot,&bits,4);}
};
void __fastcall CircleDrawHook(void* obj,void*){
  auto bytes=static_cast<unsigned char*>(obj);
  auto desc=*reinterpret_cast<unsigned char**>(bytes+8);
  if(!desc){circleOriginal(obj);return;}
  uint64_t guid;std::memcpy(&guid,desc,8);
  auto request=circles.find(guid);
  if(request==circles.end() || static_cast<int32_t>(GetTickCount()-request->second.until)>=0){circleOriginal(obj);return;}
  const float scale=*reinterpret_cast<float*>(desc+0x10);
  float* size=reinterpret_cast<float*>(bytes+0xCF0);
  if(!std::isfinite(scale)||scale<0.01f||scale>100||!std::isfinite(*size)||*size<=0){circleOriginal(obj);return;}
  RestoreFloat restore(size);
  *size=request->second.radius/scale;
  circleOriginal(obj);
}
void ExtraCircle(void* obj,uint64_t selected,DWORD now){
  if(!alwaysCircles || static_cast<int32_t>(now-alwaysUntil)>=0)return;
  auto desc=*reinterpret_cast<unsigned char**>(static_cast<unsigned char*>(obj)+8);
  if(!desc)return;
  uint64_t guid;std::memcpy(&guid,desc,8);
  if(guid==selected)return; // The original update already draws this ring.
  auto request=circles.find(guid);
  if(request==circles.end()||static_cast<int32_t>(now-request->second.until)>=0)return;
  CircleDrawHook(obj,nullptr);
}
void __fastcall VisualUpdateHook(void* obj,void*,float dt){
  visualOriginal(obj,dt);
  if(!alwaysCircles)return;
  const uint64_t selected=*at<uint64_t*>(0xB4E2D8);
  ExtraCircle(obj,selected,GetTickCount());
}
bool ready(){return *at<void**>(0xB41414)!=nullptr;}
void* object(uint64_t guid){
  if(!ready() || !guid)return nullptr;
  using Fn=void*(__fastcall*)(int,const char*,uint32_t,uint32_t,int);
  return at<Fn>(0x468460)(8,"OctoAggro",static_cast<uint32_t>(guid),static_cast<uint32_t>(guid>>32),0);
}
// The near-range nameplate path caches its raid icon. Refresh through the
// engine's own updater whenever a local request changes or is renewed.
using RefreshRaidMarker=void(__thiscall*)(void*);
RefreshRaidMarker refreshRaidMarker=at<RefreshRaidMarker>(0x608A90);
void RefreshLocalMarker(void* obj){if(obj)refreshRaidMarker(obj);}
bool RequestLocalMarker(uint64_t guid,void* obj,bool enable,DWORD now){
  if(enable){
    if(!obj || (markers.size()>=32 && markers.find(guid)==markers.end()))return false;
    markers[guid]=now+750;
  }else markers.erase(guid);
  // Erase BEFORE refresh on removal so the engine sees the real marker again.
  RefreshLocalMarker(obj);
  return true;
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
void clear(){for(const auto& entry:owned)glow(object(entry.first),false);owned.clear();
  std::unordered_map<uint64_t,DWORD> removed;markers.swap(removed);
  for(const auto& entry:removed)RefreshLocalMarker(object(entry.first));
  circles.clear();alwaysCircles=false;}
int missing(L l){settop(l,0);pushnil(l);return 1;}
int __fastcall Build(L){L l=context();settop(l,0);pushnumber(l,801);return 1;}
int __fastcall Version(L){L l=context();settop(l,0);pushnumber(l,6);return 1;}
int __fastcall Marker(L){
  L l=context();uint64_t guid=0;
  if(type(l,1)!=4 || type(l,2)!=1 || !parse(string(l,1),guid))return missing(l);
  const bool enable=boolean(l,2)!=0;
  if(!RequestLocalMarker(guid,object(guid),enable,GetTickCount()))return missing(l);
  settop(l,0);pushnumber(l,1);return 1;
}
// Enumerate locally loaded creatures, independently of nameplates/camera.
// Verified ClassicAPI ABI: callback context in ECX, GUID on stack.
using EnumCallback=int(__fastcall*)(void*,void*,uint64_t);
using EnumObjects=int(__fastcall*)(EnumCallback,void*);
struct ListContext {L lua;unsigned count;};
int __fastcall ListCreature(void* raw,void*,uint64_t guid){
  auto& scan=*static_cast<ListContext*>(raw);
  if(scan.count>=1024)return 0;
  if(static_cast<uint16_t>(guid>>48)!=0xF130)return 1;
  char text[19];std::snprintf(text,sizeof(text),"0x%08X%08X",static_cast<uint32_t>(guid>>32),static_cast<uint32_t>(guid));
  pushnumber(scan.lua,++scan.count);
  at<void(__fastcall*)(L,const char*)>(0x6F3890)(scan.lua,text);
  at<void(__fastcall*)(L,int)>(0x6F3E20)(scan.lua,-3);
  return 1;
}
int __fastcall Creatures(L){
  L l=context();settop(l,0);
  at<void(__fastcall*)(L)>(0x6F3C90)(l);
  if(ready()){ListContext scan{l,0};at<EnumObjects>(0x468380)(ListCreature,&scan);}
  return 1;
}
int __fastcall Always(L){
  L l=context();if(type(l,1)!=1)return missing(l);
  alwaysCircles=boolean(l,1)!=0;alwaysUntil=GetTickCount()+750;
  settop(l,0);pushnumber(l,1);return 1;
}
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
int __fastcall CircleRadius(L){
  L l=context();uint64_t guid=0;
  if(type(l,1)!=4 || type(l,2)!=3 || !parse(string(l,1),guid))return missing(l);
  double radius=number(l,2);
  if(!std::isfinite(radius)||radius<0||radius>60)return missing(l);
  if(radius==0)circles.erase(guid);
  else {
    if(!object(guid)||(circles.size()>=128 && circles.find(guid)==circles.end()))return missing(l);
    circles[guid]={static_cast<float>(radius),GetTickCount()+750};
  }
  settop(l,0);pushnumber(l,1);return 1;
}
void __fastcall RegisterHook(const char* name,CFn function){
  registerOriginal(name,function);
  if(!registering && name && !std::strcmp(name,"UnitXP")){
    registering=true;clear();
    registerOriginal("OctoAggroNativeVersion",Version);
    registerOriginal("OctoAggroNativeBuild",Build);
    registerOriginal("OctoAggroNativeMarker",Marker);
    registerOriginal("OctoAggroNativeCreatures",Creatures);
    registerOriginal("OctoAggroNativeGlow",Glow);
    registerOriginal("OctoAggroNativeClear",Clear);
    registerOriginal("OctoAggroNativeCircleRadius",CircleRadius);
    registerOriginal("OctoAggroNativeAlwaysCircles",Always);
    registering=false;
  }
}
void __fastcall TickHook(int a,int b,int c){
  tickOriginal(a,b,c);
  DWORD now=GetTickCount();
  if(!ready()||static_cast<int32_t>(now-alwaysUntil)>=0)alwaysCircles=false;
  for(auto it=owned.begin();it!=owned.end();){
    if(!ready() || static_cast<int32_t>(now-it->second)>=0){glow(object(it->first),false);it=owned.erase(it);}
    else ++it;
  }
  for(auto it=markers.begin();it!=markers.end();){
    if(!ready()||static_cast<int32_t>(now-it->second)>=0){
      const uint64_t guid=it->first;it=markers.erase(it);
      RefreshLocalMarker(object(guid));
    }else ++it;
  }
  for(auto it=circles.begin();it!=circles.end();){
    if(!ready()||static_cast<int32_t>(now-it->second.until)>=0)it=circles.erase(it);else ++it;
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
  if(MH_CreateHook(at<void*>(0x608E00),reinterpret_cast<void*>(CircleDrawHook),reinterpret_cast<void**>(&circleOriginal))!=MH_OK){MH_RemoveHook(MH_ALL_HOOKS);return 6;}
  if(MH_CreateHook(at<void*>(0x614A90),reinterpret_cast<void*>(VisualUpdateHook),reinterpret_cast<void**>(&visualOriginal))!=MH_OK){MH_RemoveHook(MH_ALL_HOOKS);return 7;}
  if(MH_CreateHook(at<void*>(0x4BB190),reinterpret_cast<void*>(RaidIndexHook),reinterpret_cast<void**>(&raidIndexOriginal))!=MH_OK){MH_RemoveHook(MH_ALL_HOOKS);return 8;}
  MH_QueueEnableHook(at<void*>(0x4BB190));
  MH_QueueEnableHook(at<void*>(0x614A90));
  MH_QueueEnableHook(at<void*>(0x608E00));
  MH_QueueEnableHook(at<void*>(0x704120));MH_QueueEnableHook(at<void*>(0x66FD50));
  if(MH_ApplyQueued()!=MH_OK){MH_DisableHook(MH_ALL_HOOKS);MH_RemoveHook(MH_ALL_HOOKS);return 5;}
  loaded=true;return 0;
}
BOOL WINAPI DllMain(HINSTANCE h,DWORD why,LPVOID){if(why==DLL_PROCESS_ATTACH)DisableThreadLibraryCalls(h);return TRUE;}

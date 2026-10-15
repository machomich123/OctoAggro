#include "../native/OctoAggroNative.cpp"
#include <cassert>
#include <cstdio>
uint32_t expectedLow=0x11223344,expectedHigh=0xF1300001;
int __stdcall FakeRaidIndex(uint32_t low,uint32_t high){assert(low==expectedLow && high==expectedHigh);return 8;}
struct CachedPlate {uint64_t guid;bool exists;int icon;int real;};
DWORD cacheNow=5000;
unsigned refreshCalls=0;
void __fastcall FakeRefreshPlate(void* ptr,void*){
  ++refreshCalls;auto& plate=*static_cast<CachedPlate*>(ptr);
  if(plate.exists)plate.icon=LocalMarkerIndex(plate.guid,plate.real,0x608AAC,cacheNow);
}
int main(){
 const uint64_t a=(uint64_t(expectedHigh)<<32)|expectedLow,b=a+1;
 const DWORD now=5000;
 markers.clear();
 assert(LocalMarkerIndex(a,8,0x6C70A7,now)==8);
 markers[a]=now+750;markers[b]=now+750;
 for(uintptr_t caller:{uintptr_t(0x6C70A7),uintptr_t(0x7CB834),uintptr_t(0x608AAC)}){
   assert(LocalMarkerIndex(a,8,caller,now)==7);
   assert(LocalMarkerIndex(b,8,caller,now)==7);
   for(int real=0;real<8;real++)assert(LocalMarkerIndex(a,real,caller,now)==real);
 }
 for(uintptr_t caller:{uintptr_t(0x4BB4F6),uintptr_t(0x4BBF3B),uintptr_t(0),uintptr_t(0x123456)})assert(LocalMarkerIndex(a,8,caller,now)==8);
 assert(LocalMarkerIndex(a,8,0x6C70A7,now+749)==7);
 assert(LocalMarkerIndex(a,8,0x6C70A7,now+750)==8);
 assert(LocalMarkerIndex(a+99,8,0x6C70A7,now)==8);
 markers[a]=0x100;assert(LocalMarkerIndex(a,8,0x6C70A7,0xFFFFFFF0)==7);
 assert(LocalMarkerIndex(a,8,0x6C70A7,0x101)==8);
 markers.erase(a);assert(LocalMarkerIndex(a,8,0x6C70A7,now)==8);
 // Reproduce 0.8.0: updating only the request map does not update a cached plate.
 markers.clear();CachedPlate plate{a,true,8,8};
 markers[a]=now+750;
 assert(LocalMarkerIndex(a,8,0x6C70A7,now)==7 && plate.icon==8);
 puts("REPRODUCED 0.8.0: far renderer sees skull while an existing near plate still caches no icon.");
 refreshRaidMarker=reinterpret_cast<RefreshRaidMarker>(FakeRefreshPlate);
 assert(RequestLocalMarker(a,&plate,true,now));assert(plate.icon==7);
 assert(RequestLocalMarker(a,&plate,false,now));assert(plate.icon==8);
 assert(RequestLocalMarker(a,&plate,true,now));assert(plate.icon==7);
 plate.real=2;assert(RequestLocalMarker(a,&plate,true,now));assert(plate.icon==2);
 assert(RequestLocalMarker(a,&plate,false,now));assert(plate.icon==2);
 plate.real=8;plate.exists=false;assert(RequestLocalMarker(a,&plate,true,now));
 plate.exists=true;plate.icon=8;assert(RequestLocalMarker(a,&plate,true,now));assert(plate.icon==7);
 assert(RequestLocalMarker(a,&plate,false,now));assert(plate.icon==8);
 assert(RequestLocalMarker(a,nullptr,false,now));assert(!RequestLocalMarker(a,nullptr,true,now));
 assert(refreshCalls==8);
 puts("PASS production cache refresh: enable, renew, remove, late plate creation, real-mark preservation, missing-object handling.");
 raidIndexOriginal=FakeRaidIndex;
 for(int i=0;i<1000;i++)assert(RaidIndexHook(expectedLow,expectedHigh)==8);
 puts("PASS production native marker selection: multiple skulls; real marks preserved; API callers unchanged; exact expiry and tick wrap; GUID separation; stdcall trampoline ABI.");
}

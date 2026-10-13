// Executes the actual production draw hook with a fake native draw callback.
#include "../native/OctoAggroNative.cpp"
#include <array>
#include <cassert>
#include <limits>
#include <cstdio>
float expectedDuring=0;
unsigned calls=0;
void __fastcall FakeDraw(void* obj,void*){
  ++calls;
  float value=*reinterpret_cast<float*>(static_cast<unsigned char*>(obj)+0xCF0);
  assert(value==expectedDuring);
}
int main(){
  std::array<unsigned char,0x1000> obj{};
  std::array<unsigned char,0x30> desc{};
  uint64_t id=0xF130000000000001ull;
  std::memcpy(desc.data(),&id,8);
  *reinterpret_cast<unsigned char**>(obj.data()+8)=desc.data();
  *reinterpret_cast<float*>(obj.data()+0xCF0)=1.75f;
  circleOriginal=reinterpret_cast<DrawCircle>(FakeDraw);
  const float scales[]={1,2,0.5f};
  for(float scale:scales){
    *reinterpret_cast<float*>(desc.data()+0x10)=scale;
    auto original=obj;auto originalDesc=desc;
    circles[id]={20,GetTickCount()+750};expectedDuring=20/scale;
    CircleDrawHook(obj.data(),nullptr);
    assert(obj==original && desc==originalDesc);
  }
  circles[id]={20,GetTickCount()-1};expectedDuring=1.75f;CircleDrawHook(obj.data(),nullptr);
  circles.clear();CircleDrawHook(obj.data(),nullptr);
  circles[id]={20,GetTickCount()+750};*reinterpret_cast<float*>(desc.data()+0x10)=0;
  CircleDrawHook(obj.data(),nullptr);
  *reinterpret_cast<float*>(desc.data()+0x10)=std::numeric_limits<float>::quiet_NaN();CircleDrawHook(obj.data(),nullptr);
  assert(calls==7);
  uint64_t parsed=0;assert(parse("0xF130000000000001",parsed) && parsed==id);
  assert(!parse("0x123",parsed));assert(!parse("0xF13000000000000Z",parsed));
  *reinterpret_cast<float*>(desc.data()+0x10)=1;
  DWORD now=GetTickCount();alwaysCircles=true;alwaysUntil=now+750;
  circles[id]={20,now+750};expectedDuring=20;
  const unsigned before=calls;
  ExtraCircle(obj.data(),id,now);assert(calls==before); // no duplicate selected circle
  ExtraCircle(obj.data(),0,now);assert(calls==before+1);
  assert(*reinterpret_cast<float*>(obj.data()+0xCF0)==1.75f);
  alwaysCircles=false;ExtraCircle(obj.data(),0,now);assert(calls==before+1);
  alwaysCircles=true;alwaysUntil=now-1;ExtraCircle(obj.data(),0,now);assert(calls==before+1);
  alwaysUntil=now+750;circles[id].until=now-1;ExtraCircle(obj.data(),0,now);assert(calls==before+1);
  std::puts("PASS actual circle hook: scaled radius during draw; all object and descriptor bytes restored; expired/missing/invalid-scale requests pass through; GUID validation.");
  std::puts("PASS always-visible native dispatch: draws unselected requested unit; skips selected duplicate; disabled and expired modes/requests do not draw.");
}

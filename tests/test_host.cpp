#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <cstdio>
int main(int argc,char** argv){
  if(argc!=2)return 2;
  HMODULE h=LoadLibraryA(argv[1]);if(!h){std::printf("LoadLibrary error %lu\n",GetLastError());return 3;}
  auto load=reinterpret_cast<unsigned(__cdecl*)()>(GetProcAddress(h,"Load"));
  if(!load)return 4;
  unsigned result=load();std::printf("Unsupported host rejected: Load returned %u (expected 1)\n",result);
  FreeLibrary(h);return result==1?0:5;
}

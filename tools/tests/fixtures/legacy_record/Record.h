#ifndef _RECORD_H_
#define _RECORD_H_
#include "cocos2d.h"
#include "AES.h"

using namespace cocos2d;
using namespace std;
class Record : public Ref
{
public:
	Record();
	~Record();
	static Record* GetInstance();
public:
	void saveData(char* buff, char*fileName);
//	void executeEncipherment(char* buff, const char* fileName);
	
	const char* loadData(const char*fileName);
	const char* loadDataFromPackage(const char*fileName);
	const char* getDataWithPath(string path, const char* fileName);
	
    bool deleteBuf(const char* key);
    bool writeData(const char*path,const char*fileName,const char*buf);
    void loadRecourcesCSV(const char * fileName);
private:
	void deleteMap();
	void setBuf(const char* key, char* buff);
	const char* getBuf(const char* key);
	bool isContain(const char* key);
	
	void xorEncipherment(unsigned char* pData, unsigned long size, const char* secretKey);
private:
	const char* m_keys;
	typedef map<string,const char*> BufMap;
	BufMap m_bufMap;
	static Record *m_instance;
};
#endif
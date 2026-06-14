
/**
 *  解析完的数据放到data这个二维数组中，通过getData(int m,int n)
 *  获取数据
 **/

#ifndef _CSVPARSE_
#define _CSVPARSE_


#include <stdio.h>
#include <vector>
#include "cocos2d.h"

USING_NS_CC;

using namespace std;

class CSVParse : public Ref
{
public:
    int row;
    int col;
    
public:
    CSVParse();
    ~CSVParse();
	
	virtual bool init(const char* fileName, bool foceLoadFromDocument = false, bool isFile = true, string sep = ",");
	
	static CSVParse* create(const char* fileName, bool foceLoadFromDocument = false, bool isFile = true, string sep = ",");
    
private:
    string m_fieldsep;//分隔符
    vector<vector<string> > m_data;//读取出的数据
    
private:
    void split(vector<string>& field,string line);
    int advplain(const string& line, string& fld, int);
    int advquoted(const string& line, string& fld, int);
    
    //删除替换特定字符
    void deleteChar(std::string* str);
	// 根据规则拆分字符串
    void StringSplit(const string& str, vector<string>& tokens, const char& delimiters);
    unsigned char* getFileData(const std::string& filename, const char* mode, ssize_t *size);
public:
    // 根据传入的csv文件，读取文件来初始化数据
    bool openFile(const char* fileName, bool forceLoadFromDocument = false);
	// 根据传入的const char*来初始化数据
	bool openWithString(const char* string);
    // 根据csv表格行列获取对应数据
    const char* getData(int m,int n);
};

#endif


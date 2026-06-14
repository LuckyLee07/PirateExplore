#include "CSVParse.h"

CSVParse::CSVParse()
{

}

CSVParse::~CSVParse()
{
    for (int i = 0; i < m_data.size(); i++) {
        m_data[i].clear();
    }
    m_data.clear();
}

bool CSVParse::init(const char* fileName, bool foceLoadFromDocument, bool isFile, string sep)
{
	bool success = false;
	do {
		m_fieldsep = sep;
		// 打开文件
//		if (isFile) {
//			CC_BREAK_IF(!openFile(fileName, foceLoadFromDocument));
//		} else {
//			CC_BREAK_IF(!openWithString(fileName));
//		}
        CC_BREAK_IF(!openFile(fileName, foceLoadFromDocument));
		success = true;
	} while (0);
	return success;
}

CSVParse* CSVParse::create(const char* fileName, bool foceLoadFromDocument, bool isFile, string sep)
{
	CSVParse* instance = new CSVParse();
	if (instance && instance->init(fileName, foceLoadFromDocument, isFile, sep)) {
		instance->autorelease();
		return instance;
	}
	CC_SAFE_DELETE(instance);
	return NULL;
}

// split: split line into fields
void CSVParse::split(vector<string>& field,string line)
{
    string fld;
    int i, j;
    
    if (line.length() == 0)
        return ;
    i = 0;
    
    do {
        if (i < line.length() && line[i] == '"')
            j = advquoted(line, fld, ++i);    // skip quote
        else
            j = advplain(line, fld, i);
        
        field.push_back(fld);
        i = j + 1;
    } while (j < line.length());
    
}

// advquoted: quoted field; return index of next separator
int CSVParse::advquoted(const string& s, string& fld, int i)
{
    int j;
    
    fld = "";
    for (j = i; j < s.length(); j++) {
        if (s[j] == '"' && s[++j] != '"') {
            int k = s.find_first_of(m_fieldsep, j);
            if (k > s.length())    // no separator found
                k = s.length();
            for (k -= j; k-- > 0; )
                fld += s[j++];
            break;
        }
        fld += s[j];
    }
    return j;
}

// advplain: unquoted field; return index of next separator
int CSVParse::advplain(const string& s, string& fld, int i)
{
    int j;
    
    j = s.find_first_of(m_fieldsep, i); // look for separator
    if (j > s.length())               // none found
        j = s.length();
    fld = string(s, i, j-i);
    return j;
}


// getfield: return n-th field
const char* CSVParse::getData(int m,int n)
{
    if ( m<0 || m>=m_data.size() || n<0 || n>=m_data[m].size() ) {
        return "";
    }
    
    //printf("%d,%d,%s\n", m, n, m_data[m][n].c_str());
    
    return m_data[m][n].c_str();
}



void CSVParse::StringSplit( const string& str, vector<string>& tokens, const char& delimiters )
{
    string::size_type lastPos = str.find_first_not_of(delimiters, 0);
    string::size_type pos = str.find_first_of(delimiters, lastPos);
    while (string::npos != pos || string::npos != lastPos)
    {
        tokens.push_back(str.substr(lastPos, pos-lastPos));
        lastPos = str.find_first_not_of(delimiters, pos);
        pos = str.find_first_of(delimiters, lastPos);
    }
    
//    string temp = str;
//    string::size_type lastPos = temp.find_first_not_of(delimiters, 0);
//    string::size_type pos = temp.find_first_of(delimiters, lastPos);
//    if (pos == -1||(lastPos==pos))//没找到
//    {
//        str = NULL;
//        nstr = NULL;
//        return;
//    }
//    int size = strlen(str);
//    
//    const char* mstr =  temp.substr(pos,size-1).c_str();
//    CCString* mcstr = CCString::create(mstr);
//    const char* ostr =  temp.substr(lastPos, pos).c_str();
//    memcpy(nstr, ostr, strlen(ostr));
//    
//
//    memset(str, 0, size);
//    memcpy(str, mcstr->getCString(), size - pos);
}


//读取方式: 逐行读取, 将行读入字符串, 行之间用回车换行区分
//If you want to avoid reading into character arrays, 
//you can use the C++ string getline() function to read lines into strings
bool CSVParse::openFile(const char* fileName, bool forceLoadFromDocument/* = false*/)
{
    unsigned char* pBuffer = NULL;
    ssize_t bufferSize = 0;
//	if (forceLoadFromDocument) {
//		string documentPath = CCFileUtils::sharedFileUtils()->getWritablePath();
//		documentPath += fileName;
//		pBuffer = CCFileUtils::sharedFileUtils()->getFileData(documentPath.c_str(), "r", &bufferSize);
//	} else {
//		
//	}
    
    
    pBuffer = this->getFileData(fileName, "r", &bufferSize);
	if (!pBuffer) {
		return false;
	}
    
    string s = (char*)pBuffer;
    string str = s.substr(0,bufferSize);
    
    vector<string> line;
    StringSplit(str, line, '\n');
    for (unsigned int i = 0; i < line.size(); ++i) {
        deleteChar(&line[i]);
        vector<string> field;
        split(field, line[i]);
        if (i > 0) {
            field.erase(field.begin());
            m_data.push_back(field);
        }
//        col = max(col, (int)field.size());
    }
    
    row = m_data.size();
	if (row > 0) {
		col = m_data[0].size();
	} else {
		col = 0;
	}
    CC_SAFE_DELETE_ARRAY(pBuffer);
    return true;
    
    
//    // 获取全路径 zp up
////    const char* pathKey = cocos2d::CCFileUtils::sharedFileUtils()->fullPathFromRelativePath(fileName);
//    const char* pathKey = cocos2d::CCFileUtils::sharedFileUtils()->fullPathForFilename(fileName).c_str();
//    
//    //打开文件
//    unsigned long nSize = 0;
//    const char* pBuffer = (const char*)CCFileUtils::sharedFileUtils()->getFileData(pathKey, "rb", &nSize);
//    if( !pBuffer ) {
//		CCLOG("打开csv文件%s失败", pathKey);
//		assert(false);
//        return false;
//    }
//    
//    
//    
////    FILE *fp = fopen(pathKey, "r");
////    if( !fp ) {
////		CCLOG("打开csv文件%s失败", pathKey);
////		assert(false);
////        return false;
////    }
//    
//    char* tempstr = new char[strlen(pBuffer)+1];
//    memcpy(tempstr, pBuffer, strlen(pBuffer));
//    CC_SAFE_DELETE_ARRAY(pBuffer);
//    
//    
//    char tmpChar[2048] = {0};
//    string s;
//    
//    //去掉\r
//    int lineIndex = 0;
//   
////	CCLOG("内存剩余:%f",getNotUsedMemory());
//    //读取第一行
////    fgets(tmpChar, 2048, fp);
//    StringSplit(tmpChar,tempstr, '\n');
//    
//    while( strlen(tempstr) > 0 )
//    {
//        s = pBuffer;
//        //printf("%d = %s", lineIndex, tmpChar);
//        
//        //删除和替换掉多余字符
//        deleteChar(&s);
//        
//        //拆分掉文本
//        std::vector<string> field;
//        split(field, s);
//        
//        //第一行和第一列是无用数据,所以不存.
//        if(lineIndex > 0){
//            field.erase(field.begin());
//            m_data.push_back(field);
//        }
//        lineIndex++;
//        
//        //读取下一行
//        memset(tmpChar, '\0', strlen(tmpChar));
////        fgets(tmpChar, 2048, fp);
//		StringSplit(tmpChar,tempstr, '\n');
////		CCLOG("内存剩余1:%f",getNotUsedMemory());
//    }
//    
//    row = m_data.size();
//    col = m_data[0].size();
//    
//    //输出内容
////    for (int i=0; i<m_data.size(); i++) {
////        for (int k=0; k<m_data[i].size(); k++) {
////            CCLOG("--------->%s",getData(i, k));
////        }
////    }
//    
//    
////    fclose(fp);
//    
//    return true;
}

bool CSVParse::openWithString(const char* _string)
{
    //获取全路径
//    std::string pathKey;
//    pathKey.insert(0, string);
//    pathKey.insert(0, CCFileUtils::sharedFileUtils()->getWriteablePath());
    if (!_string) {
		return false;
	}
    
    // zp up
    string str = _string;
    
    vector<string> line;
    StringSplit(str, line, '\n');
    for (unsigned int i = 0; i < line.size(); ++i) {
        deleteChar(&line[i]);
        vector<string> field;
        split(field, line[i]);
        if (i > 0) {
            field.erase(field.begin());
            m_data.push_back(field);
        }
//		col = max(col, (int)field.size());
    }
    
    row = m_data.size();
	if (row > 0) {
		col = m_data[0].size();
	} else {
		col = 0;
	}
    return true;
}


void CSVParse::deleteChar(std::string* str)
{
    string::iterator it;
    int index = 0;
    for (; index < str->size();) {
        it = str->begin()+index;
        if ( *it == '\r' || *it == '\n') {
            str->erase(it);
        } else {
            index++;
        }
    }    
}
 unsigned char* CSVParse::getFileData(const std::string& filename, const char* mode, ssize_t *size)
{
    unsigned char * buffer = nullptr;
    CCASSERT(!filename.empty() && size != nullptr && mode != nullptr, "Invalid parameters.");
    *size = 0;
    do
    {
        // read the file from hardware
        FILE *fp = fopen(filename.c_str(), mode);
        CC_BREAK_IF(!fp);
        
        fseek(fp,0,SEEK_END);
        *size = ftell(fp);
        fseek(fp,0,SEEK_SET);
        buffer = (unsigned char*)malloc(*size);
        *size = fread(buffer,sizeof(unsigned char), *size,fp);
        fclose(fp);
    } while (0);
    
    if (! buffer)
    {
        std::string msg = "Get data from file(";
        msg.append(filename).append(") failed!");
        
        CCLOG("%s", msg.c_str());
    }
    return buffer;
}

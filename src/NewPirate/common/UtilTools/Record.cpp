#include "Record.h"
#include "ZQCSVParse.h"
#include "RecordCodec.h"

#include <cstring>
#include <string>
#include <vector>

Record* Record::m_instance = NULL;
Record::Record()
{
	m_keys = "jhG8i8ekb23sd438";
}

Record::~Record()
{
	deleteMap();
}


//void Record::saveData(char*buff,char*fileName )
//{
//    
//    //	char miwen_hex[102400];
//    //    fileName = "sdsd";
////    char ssss[1024];
//    //    sprintf(ssss, "%s_1", fileName);
//    
//    char* miwen_hex = buff;
//    //	string keys = m_keys + fileName;
//    //	AES aes((unsigned char*)keys.c_str());
//    //	aes.Cipher(buff, miwen_hex);
//    string path = FileUtils::getInstance()->getWritablePath() + fileName;
//    FILE *pFile = fopen(path.c_str(),"w");
////    size_t _length = strlen(miwen_hex);
//    //	size_t m_insertNumsBegin = 201704;
//    //	size_t m_insertNumsEnd = 407102;
//    //	fwrite(&m_insertNumsBegin,sizeof(size_t),1,pFile);
//    //	fwrite(&_length,sizeof(size_t),1,pFile);
//    //	fwrite(&m_insertNumsEnd,sizeof(size_t),1,pFile);
//    fwrite(miwen_hex,sizeof(char), strlen(miwen_hex),pFile);
//    fclose(pFile);
//    deleteBuf(fileName);
//    //	CCLOG("saveData===%s",miwen_hex);
//    
//}
//
//const char* Record::loadData( const char*fileName )
//{
//    const char * bufData = NULL;
//    string path = FileUtils::getInstance()->getWritablePath() + fileName;
//    if(FileUtils::getInstance()->isFileExist(path.c_str()))
//    {
//        bufData = getBuf(fileName);
//        if (!bufData)
//        {
//            //            string keys = m_keys + fileName;
//            //            AES aesRead((unsigned char*)keys.c_str());
//            FILE*pRead = fopen(path.c_str(),"r");
////            size_t _resultLength = 0;
//            //            size_t _insertNumBegin = 0;
//            //            size_t _insertNunEnd = 0;
//            //            fread(&_insertNumBegin,sizeof(size_t),1,pRead);
//            //            fread(&_resultLength,sizeof(size_t),1,pRead);
//            //            fread(&_insertNunEnd,sizeof(size_t),1,pRead);
//            //            char * buff = new char[_resultLength + 1];
//            
//            fseek(pRead,0,SEEK_END);
//            size_t size = ftell(pRead);
//            fseek(pRead,0,SEEK_SET);
//            
//            char * buffChar = new char[size+1];
//            
//            fread(buffChar,sizeof(char),size,pRead);
//            fclose(pRead);
//            buffChar[size] = '\0';
//            //            aesRead.InvCipher(buff, buffChar);
//            //CCLOG("loadData===%s",buffChar);
//            //            delete[]buff;
//            m_bufMap.insert(BufMap::value_type(fileName,buffChar));
//            bufData = buffChar;
//        }
//    }
//    return bufData;
//}


void Record::saveData(char*buff, char*fileName)
{
	if (buff == NULL || fileName == NULL || buff[0] == '\0' || fileName[0] == '\0')
	{
		CCLOG("Record refused an empty save request");
		return;
	}

	std::vector<unsigned char> encoded;
	if (!RecordCodec::encode(std::string(buff), encoded))
	{
		CCLOG("Record failed to encode save: %s", fileName);
		return;
	}

	const std::string path = FileUtils::getInstance()->getWritablePath() + fileName;
	if (!RecordCodec::writeFileAtomically(path, encoded))
	{
		CCLOG("Record failed to atomically write save: %s", fileName);
		return;
	}

	// Invalidate only after the replacement succeeds. On any write failure the
	// previous file and its cached representation remain usable.
	deleteBuf(fileName);
}

//void Record::executeEncipherment(char* buff, const char* fileName)
//{
//	unsigned long len = strlen(buff);
//	unsigned char* lzss_data = new unsigned char[len];
//	memset(lzss_data, 0, len);
//	//	AES aes((unsigned char*)keys.c_str());
//	//	aes.Cipher(buff, miwen_hex);
//	// 先使用lzss压缩
//	LZSS lzssInstance;
//	unsigned long lzss_len = lzssInstance.Compress((unsigned char*)buff, len, lzss_data);
//	// 验证字符串 + 文件长度 + lzss文件长度 + lzss(真实数据)
//	char ulLen = sizeof(unsigned long);
//	// 总体文件长度等于
//	int place = sizeof(char);
//	unsigned long saveLen = place + ulLen * 2 + lzss_len ;
//	unsigned char* pSavaBuf = new unsigned char[saveLen];
//	memset(pSavaBuf, 0, sizeof(unsigned char)*saveLen);
//	
//	// 向数据中加入数据加密平台位数
//	memcpy(pSavaBuf, &ulLen, place);
//	// 加入原始文件长度
//	memcpy(pSavaBuf + place, &len, ulLen);
//	// 再加入lzss数据长度
//	memcpy(pSavaBuf + place + ulLen, &lzss_len, ulLen);
//	// 再加入真实数据
//	memcpy(pSavaBuf + place + ulLen * 2, lzss_data, lzss_len);
//	// 加密之后进行秘钥混淆
//	this->xorEncipherment(pSavaBuf, saveLen, m_keys);
//	string path = FileUtils::getInstance()->getWritablePath() + fileName;
//	FILE *pFile = fopen(path.c_str(),"wb");
////	printf("fileName:%s length:%ld", fileName, lzss_len);
//	fwrite(pSavaBuf, sizeof(unsigned char), saveLen, pFile);
//	fclose(pFile);
//	delete []pSavaBuf;
//	delete []lzss_data;
//	//	CCLOG("saveData===%s",miwen_hex);
//}

const char* Record::loadData( const char*fileName )
{
    string path = FileUtils::getInstance()->getWritablePath() + fileName;
	return this->getDataWithPath(path, fileName);
}

const char* Record::loadDataFromPackage(const char*fileName)
{
	string path = FileUtils::getInstance()->fullPathForFilename(fileName);
	return this->getDataWithPath(path, fileName);
}

const char* Record::getDataWithPath(string path, const char* fileName)
{
	const char * bufData = NULL;
	if (fileName == NULL || fileName[0] == '\0')
	{
		return NULL;
	}
	if (FileUtils::getInstance()->isFileExist(path)) {
		bufData = getBuf(fileName);
		if (!bufData) {
			std::vector<unsigned char> encoded;
			std::string decoded;
			if (!RecordCodec::readFile(path, encoded) ||
				!RecordCodec::decode(&encoded[0], encoded.size(), decoded))
			{
				CCLOG("Record rejected a corrupt or truncated save: %s", fileName);
				return NULL;
			}

			char* decodedBuffer = new char[decoded.size() + 1u];
			std::memcpy(decodedBuffer, decoded.data(), decoded.size());
			decodedBuffer[decoded.size()] = '\0';
			this->setBuf(fileName, decodedBuffer);
			bufData = decodedBuffer;
		}
	}
	return bufData;
}

void Record::deleteMap()
{
	if (!m_bufMap.empty())
	{
		BufMap::iterator it = m_bufMap.begin();
		for (; it != m_bufMap.end(); ++it)
		{
			const char *_buf = it->second;
			delete[]_buf;
		}
		m_bufMap.clear();
	}
}

void Record::setBuf(const char* key, char* buff)
{
	if (key == NULL || buff == NULL)
	{
		return;
	}
	BufMap::iterator it = m_bufMap.find(key);
	if (it != m_bufMap.end())
	{
		delete []it->second;
		m_bufMap.erase(it);
	}
	m_bufMap.insert(BufMap::value_type(key, buff));
}

const char* Record::getBuf( const char* key )
{
	if (!m_bufMap.empty())
	{
		BufMap::iterator it = m_bufMap.find(key);
		if(it != m_bufMap.end())
		{
			return it->second;
		}
	}
	return NULL;
}

bool Record::deleteBuf( const char* key )
{
	if (!m_bufMap.empty())
	{
		BufMap::iterator it = m_bufMap.find(key);
		if(it != m_bufMap.end())
		{
			const char *_buf = it->second;
			delete[]_buf;
            m_bufMap.erase(it);
			return true;
		}
	}
	return false;
}

bool Record::isContain(const char* key)
{
	if (!m_bufMap.empty())
	{
		BufMap::iterator it = m_bufMap.find(key);
		if(it != m_bufMap.end())
		{
			return true;
		}
	}
	return false;
}

Record* Record::GetInstance()
{
	if (!m_instance)
	{
		m_instance = new Record();
	}
	return m_instance;
}

bool Record::writeData(const char*path,const char*fileName,const char*buf)
{
    if (!buf || !path || path[0] == '\0')
    {
        return false;
    }
    FILE*pFile = fopen(path,"wb");
    if (pFile == NULL)
    {
        return false;
    }
    const size_t size = strlen(buf);
    const bool wroteAll = fwrite(buf,sizeof(char),size,pFile) == size;
    const bool flushed = fflush(pFile) == 0;
    const bool closed = fclose(pFile) == 0;
    return wroteAll && flushed && closed;
}
void Record::loadRecourcesCSV(const char * fileName)
{
    CSVParseManager::shareManager()->writeResourceCSV(fileName);
}

// 循环亦或加解密
void Record::xorEncipherment(unsigned char* pData, unsigned long size, const char* secretKey)
{
	unsigned char* pSrc = pData;
	unsigned char* pKey = (unsigned char*)secretKey;
	if (!pSrc || !pKey) return;
	
	size_t max = strlen(secretKey);
	for (int i = 0; i < size; ++i) {
		*pSrc ^= *pKey;
		pSrc++;
		if (i % max == 0) {
			pKey = (unsigned char*)secretKey;
		}
		pKey++;
	}
}


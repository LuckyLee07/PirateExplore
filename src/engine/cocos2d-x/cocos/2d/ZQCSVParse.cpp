//
//  ZQCSVParse.cpp
//  WarCraftCardGame
//
//  Created by ourpalm on 10/19/12.
//
//

#include "ZQCSVParse.h"
ZQCSVParse* ZQCSVParse::m_instatce = NULL;

ZQCSVParse::ZQCSVParse():m_csv(NULL), m_isCreateWithManager(false)
{
	
}

ZQCSVParse::~ZQCSVParse()
{
	CC_SAFE_DELETE(m_csv);
}
bool ZQCSVParse::initWithFile(const char* file, bool isFoceLoadFromDocument, bool isCreateWithManager)
{
	m_csv = CSVParse::create(file, isFoceLoadFromDocument);
	if (!m_csv) {
		return false;
	}
	m_csv->retain();
	m_isCreateWithManager = isCreateWithManager;
	int row = m_csv->row;
	// 循环行列，注意：这里csv的{0, 0}行都是默认不读取的
	for (int i = 1; i < row; i++) {
		const char* fileName = m_csv->getData(i, 0);
        const char* md5 = m_csv->getData(i, 1);
        if (!getDicForKey(fileName))
        {
            m_index.insert(std::make_pair(fileName, md5));
        }
       
	}
	return true;
}

/*
 * file:csv文件名
 * isFoceLoadFromDocument:是否强制从document下读取
 * isCreateWithManager:是否是通过csvmanager创建的，如果是，那么在释放那里有处理
 */
void ZQCSVParse::createParse(const char* file, bool isFoceLoadFromDocument, bool isCreateWithManager)
{
    initWithFile(file, isFoceLoadFromDocument, isCreateWithManager);
}

#pragma mark - 非静态实例调用的的函数

bool ZQCSVParse::getDicForKey(const char* key)
{
    if(!m_index.empty())
    {
        std::map<string,string>::iterator it = m_index.find(key);
        if (it != m_index.end()) {
            
            return true;
        }
    }
	return false;
}

ssize_t ZQCSVParse::count()
{
	return m_index.size();
}


CSVParseManager* CSVParseManager::m_instance=NULL;

CSVParseManager::CSVParseManager():m_csvParse(0)
{
    
}
CSVParseManager::~CSVParseManager()
{
    CC_SAFE_DELETE(m_csvParse);
}
CSVParseManager* CSVParseManager::shareManager()
{
    if (m_instance == NULL)
    {
        m_instance = new CSVParseManager();
    }
    return m_instance;
}
bool CSVParseManager::getDicForKey(const char* key)
{
    if (!m_csvParse) {
        return  false;
    }
    return  m_csvParse->getDicForKey(key);
}
void CSVParseManager::writeResourceCSV(const char*fileName)
{
    if (m_csvParse == NULL && fileName != NULL)
    {
        m_csvParse = new ZQCSVParse();
        m_csvParse->createParse(fileName);
    }
}



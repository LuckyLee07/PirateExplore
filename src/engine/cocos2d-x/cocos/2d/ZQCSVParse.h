//
//  ZQCSVParse.h
//  WarCraftCardGame
//
//  Created by ourpalm on 10/19/12.
//
//

/* CSV解析类 Ver 1.1
 * 使用方法简介：
 * 1.生成csv的字典，注意这里返回的字典是自释放类型，所以请酌情控制
 * ZQCSVParse *csv = ZQCSVParse::create("MissionActData.csv");
 * 之后再CCDictionary* dic = csv->getDicForKey("1");获取
 * 2.返回的字典数据结构
 * {
 *		key1:value1,
 *		key2:value2,
 *		key3:value3, ...
 * }
 * 每一个value就是一个ccstring
 * 3.注意事项
 * 这个解析csv的代码是csv最左侧和最顶部的这两行是不读取的，所以写excel的时候请注意
 * -----------------------------------------------------------------------
 * 1.1版本加入新特性：
 * 一.持久化csv在内存里，这里写了一个新类来控制：zqcsvmanager；建议使用方法：
 * 1.zqCsv->getCsv("这里是csv的名字");
 * 2.以上代码返回一个ZQCSVParse实例，用法请参照之前的写法
 * 3.用过这个csv之后如果确定其他地方不用或者其他地方用的很少的时候，
 *   可以用如下代码删除以减少内存占用
 * 4.zqCsv->releaseCsv("这里是csv的名字");
 * 5.如果需要彻底清理csv的dictionary，请使用如下：
 * 6.zqCsv->cleanFactory();
 * 二.请注意，通过manager创建的csv不能显式的调用retain和release
 */

#ifndef WarCraftCardGame_ZQCSVParse_h
#define WarCraftCardGame_ZQCSVParse_h

#include "cocos2d.h"
#include "CSVParse.h"

USING_NS_CC;
using namespace std;
class ZQCSVParse
{
    
public:
	ZQCSVParse();
	~ZQCSVParse();
	
    bool initWithFile(const char* file, bool isFoceLoadFromDocument = false, bool isCreateWithManager = false);
	/*
	 * file:csv文件名
	 * isFoceLoadFromDocument:是否强制从document下读取
	 * isCreateWithManager:是否是通过csvmanager创建的，如果是，那么在释放那里有处理
	 */
	 void createParse(const char* file, bool isFoceLoadFromDocument = false, bool isCreateWithManager = false);
	
public:
	/*
	 * 使用非静态方法返回某一条数据字典的方法
	 */
	bool getDicForKey(const char* key);
	
	/**
	 * create后获得array的方法
	 */
	//CCArray* getArrayWithInstance();
	
	/*
	 * 使用非静态方法返回数据总量
	 */
	ssize_t count();
	
private:
    static ZQCSVParse *m_instatce;
private:
	//CCDictionary*				m_index;				// 索引数据
    std::map<string, string>             m_index;
	CSVParse*					m_csv;					// csv纯c数据
	
	bool						m_isCreateWithManager;	// 是否通过manager实例化
    
};
class CSVParseManager
{
public:
    static CSVParseManager* shareManager();
    bool getDicForKey(const char* key);
    void writeResourceCSV(const char*fileName);
protected:
    CSVParseManager();
    ~CSVParseManager();
private:
    static CSVParseManager* m_instance;
    ZQCSVParse *m_csvParse;
};

#endif

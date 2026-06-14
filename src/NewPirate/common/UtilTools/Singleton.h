#ifndef _SINGLETON_H_
#define _SINGLETON_H_

template<class T>
class  Singleton
{
private:
	static T * iInstance;
public:
	static T * getInstance();
	static void FreeInstance();
};

template<class T>
T * Singleton<T>::iInstance=0;

template<class T>
T * Singleton<T>::getInstance()
{
	if(iInstance == 0)
	{
		iInstance=new T();
	}
    
	return iInstance;
}

template<class T>
void Singleton<T>::FreeInstance()
{
	if(iInstance)
	{
		delete iInstance;
		iInstance=0;
	}
}

#endif
#include "AppDelegate.h"
#include "cocos2d.h"
#include <cstdlib>
#include <unistd.h>
#include <limits.h>

int main(int argc, char **argv) {
    AppDelegate app;
    char executable[PATH_MAX] = {};
    const ssize_t size = readlink("/proc/self/exe", executable, sizeof(executable) - 1);
    if (size <= 0) return 1;
    const std::string executablePath(executable);
    const std::string directory = executablePath.substr(0, executablePath.find_last_of('/'));
    cocos2d::FileUtils::getInstance()->addSearchPath(directory + "/engine-scripts");
    int width = 480, height = 900;
    if (argc == 3) {
        width = std::atoi(argv[1]); height = std::atoi(argv[2]);
        if (width < 320 || height < 480) return 2;
    }
    auto view = cocos2d::GLView::createWithRect("PirateExplore - Native Linux",
        cocos2d::Rect(0, 0, width, height));
    if (!view) return 1;
    cocos2d::Director::getInstance()->setOpenGLView(view);
    return cocos2d::Application::getInstance()->run();
}

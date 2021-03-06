import ceylon.collection {
    ArrayList
}
import ceylon.language.meta {
    modules
}
import ceylon.test {
    createTestRunner,
    TestListener,
    TestSource,
    TestRunResult,
    TestFilter,
    defaultTestFilter
}

import ceylon.test.reporter {
    HtmlReporter,
    TapReporter
}

import ceylon.test.engine {
    TagFilter
}


shared class Runner() {
    
    value options = Options.parse();
    value socket = connectSocket(options.port);
    
    shared void run() {
        try {
            initializeTestedModules();
            value testSources = getTestSources();
            value testListeners = getTestListeners();
            value testFilter = getTestFilter();
            value result = createTestRunner(testSources, testListeners, testFilter).run();
            handleResult(result);
        } finally {
            socket?.close();
        }
    }
    
    TestSource[] getTestSources() {
        value testSources = ArrayList<TestSource>();
        
        if (options.tests.empty) {
            for (value mod in options.modules) {
                assert (exists m = modules.find(*parseModuleNameAndVersion(mod)));
                testSources.add(m);
            }
        } else {
            testSources.addAll(options.tests);
        }
        
        return testSources.sequence();
    }
    
    TestListener[] getTestListeners() {
        value testListeners = ArrayList<TestListener>();
        
        if (exists socket) {
            testListeners.add(TestEventPublisher(socket.write));
        } else if (options.tap) {
            testListeners.add(TapReporter());
        } else {
            testListeners.add(TestLoggingListener(options.colorReset, options.colorGreen, options.colorRed));
        }
        if (options.report) {
            testListeners.add(HtmlReporter(getHtmlReportSubdir()));
        }
        
        return testListeners.sequence();
    }
    
    TestFilter getTestFilter() {
        if( options.tags.empty ) {
            return defaultTestFilter;
        } else {
            return TagFilter(options.tags).filterTest;
        }
    }
    
    [String, String] parseModuleNameAndVersion(String mod) {
        assert (exists i = mod.firstInclusion("/"));
        value name = mod[0 .. i-1];
        value version = mod[i+1 ...];
        
        return [name, version];
    }
    
    native
    void handleResult(TestRunResult result);
    
    native("jvm")
    void handleResult(TestRunResult result) {
        if (!result.isSuccess) {
            throw TestFailureException();
        }
    }
    
    native("js")
    suppressWarnings("expressionTypeNothing")
    void handleResult(TestRunResult result) {
        if (!socket exists) {
            process.exit(result.isSuccess then 0 else 100);
        }
    }
    
    native
    void initializeTestedModules();
    
    native("jvm")
    void initializeTestedModules() {
        void loadModule(String modName, String modVersion) {
            /*
             workaround until issue https://github.com/ceylon/ceylon/issues/5763 will be solved
             the final code should looks like...
             
             ```
             ​import ceylon.modules.jboss.runtime { CeylonModuleLoader }
             
             assert(is CeylonModuleLoader loader = ceylonModuleLoader);
             loader.loadModuleSynchronous(modName, modVersion);
             ```
             
             */
            Workaround.loadModule(modName, modVersion);
        }
        
        for (value mod in options.modules) {
            loadModule(*parseModuleNameAndVersion(mod));
        }
    }
    
    native("js")
    void initializeTestedModules() {
        for (value mod in options.modules) {
            assert (exists m = modules.find(*parseModuleNameAndVersion(mod)));
        }
    }
    
    native
    String getHtmlReportSubdir();
    
    native("jvm")
    String getHtmlReportSubdir() => "test";
    
    native("js")
    String getHtmlReportSubdir() => "test-js";
    
}

class TestFailureException() extends Exception() {
}

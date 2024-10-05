#Requires AutoHotkey v2.0+

class TestClass {
    sayHello() {
        MsgBox "Hello from TestClass!"
    }
}

testObj := new TestClass()
testObj.sayHello()
# bench-using-ns-impl

C++ Compile Speed Test

## using namespace for class implimentation

## A

```c++
namespace Test
{
class Hoge
{
public:
    void f();
};
}
```

```c++
namespace Test
{

void Hoge::f()
{
}

}
```

## B

```c++
namespace Test
{
class Hoge
{
public:
    void f();
};
}
```

```c++
using namespace Test;

void Hoge::f()
{
}

```

## Benchmark Result

![ubuntu](images/ubuntu.png)

![mac](images/mac.png)

![winA](images/winA.png)
![winB](images/winB.png)

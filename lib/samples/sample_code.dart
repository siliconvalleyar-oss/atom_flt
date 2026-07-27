class SampleCode {
  SampleCode._();

  static const cpp = '''#include <iostream>
#include <vector>
#include <memory>
#include <algorithm>
#include <thread>
#include <mutex>
#include <optional>
#include <variant>
#include <concepts>
#include <ranges>

// ============================================================
// 1. CLASE BASE CON FUNCION VIRTUAL
// ============================================================
class Shape {
protected:
    std::string name;
    static int totalShapes;

public:
    Shape(const std::string& n) : name(n) { totalShapes++; }
    virtual ~Shape() = default;

    virtual double area() const = 0;
    virtual void draw() const {
        std::cout << "Drawing " << name << "\\n";
    }

    std::string getName() const { return name; }
    static int getTotalShapes() { return totalShapes; }
};

int Shape::totalShapes = 0;

// ============================================================
// 2. HERENCIA Y POLIMORFISMO
// ============================================================
class Circle : public Shape {
    double radius;
public:
    Circle(double r) : Shape("Circle"), radius(r) {}

    double area() const override {
        return 3.14159265359 * radius * radius;
    }

    void draw() const override {
        std::cout << "  ( )\\n";
        std::cout << " (   ) radius=" << radius << "\\n";
        std::cout << "  ( )\\n";
    }
};

class Rectangle : public Shape {
    double w, h;
public:
    Rectangle(double w, double h) : Shape("Rectangle"), w(w), h(h) {}

    double area() const override {
        return w * h;
    }

    void draw() const override {
        std::cout << " +------+\\n";
        std::cout << " |      | w=" << w << " h=" << h << "\\n";
        std::cout << " +------+\\n";
    }
};

// ============================================================
// 3. TEMPLATES
// ============================================================
template <typename T>
class Box {
    T value;
public:
    explicit Box(T v) : value(v) {}

    T get() const { return value; }
    void set(T v) { value = v; }

    template <typename U>
    Box<T> operator+(const Box<U>& other) const {
        return Box<T>(value + static_cast<T>(other.get()));
    }
};

// Template specialization
template <>
class Box<bool> {
    bool value;
public:
    explicit Box(bool v) : value(v) {}
    bool get() const { return value; }
};

// ============================================================
// 4. CONCEPTS (C++20)
// ============================================================
template <typename T>
concept Numeric = std::is_arithmetic_v<T>;

template <Numeric T>
T sum(const std::vector<T>& values) {
    T total = 0;
    for (const auto& v : values) total += v;
    return total;
}

// ============================================================
// 5. LAMBDAS Y ALGORITMOS STL
// ============================================================
auto processVector(const std::vector<int>& input) {
    std::vector<int> result;
    std::ranges::copy_if(
        input | std::views::transform([](int x) { return x * 2; }),
        std::back_inserter(result),
        [](int x) { return x > 10; }
    );
    return result;
}

// ============================================================
// 6. SMART POINTERS Y MOVE SEMANTICS
// ============================================================
class Resource {
    std::string data;
public:
    explicit Resource(std::string d) : data(std::move(d)) {}
    Resource(Resource&&) = default;
    Resource& operator=(Resource&&) = default;

    Resource(const Resource&) = delete;
    Resource& operator=(const Resource&) = delete;

    const std::string& getData() const { return data; }
};

auto createResource() {
    return std::make_unique<Resource>("unique data");
}

void demonstrateMove() {
    auto res = createResource();
    auto moved = std::move(res);
    // res is now nullptr
}

// ============================================================
// 7. VARIANT Y OPTIONAL
// ============================================================
using ConfigValue = std::variant<int, double, std::string>;

struct Config {
    std::string key;
    ConfigValue value;
};

std::optional<Config> findConfig(const std::string& key) {
    if (key == "timeout") {
        return Config{"timeout", 30};
    }
    return std::nullopt;
}

// ============================================================
// 8. MULTI-THREADING
// ============================================================
class ThreadSafeCounter {
    mutable std::mutex mtx;
    int count = 0;
public:
    void increment() {
        std::lock_guard<std::mutex> lock(mtx);
        count++;
    }

    int get() const {
        std::lock_guard<std::mutex> lock(mtx);
        return count;
    }
};

void parallelWork() {
    ThreadSafeCounter counter;
    std::vector<std::thread> threads;

    for (int i = 0; i < 10; i++) {
        threads.emplace_back([&counter]() {
            for (int j = 0; j < 1000; j++) {
                counter.increment();
            }
        });
    }

    for (auto& t : threads) t.join();
    std::cout << "Final count: " << counter.get() << "\\n";
}

// ============================================================
// 9. CONSTEXPR Y COMPILE-TIME
// ============================================================
constexpr unsigned long long factorial(unsigned int n) {
    return (n <= 1) ? 1 : n * factorial(n - 1);
}

constexpr auto compileTimeFactorial = factorial(10);

// ============================================================
// 10. VARIADIC TEMPLATES
// ============================================================
template <typename... Args>
auto sumAll(Args... args) {
    return (args + ...);  // Fold expression (C++17)
}

template <typename... Args>
void printAll(Args... args) {
    ((std::cout << args << " "), ...);
    std::cout << "\\n";
}

// ============================================================
// 11. RAII Y EXCEPTION SAFETY
// ============================================================
class FileHandler {
    FILE* file;
public:
    explicit FileHandler(const char* path)
        : file(fopen(path, "r")) {
        if (!file) throw std::runtime_error("Cannot open file");
    }

    ~FileHandler() {
        if (file) fclose(file);
    }

    FileHandler(const FileHandler&) = delete;
    FileHandler& operator=(const FileHandler&) = delete;

    std::string readLine() {
        char buffer[1024];
        if (fgets(buffer, sizeof(buffer), file)) {
            return std::string(buffer);
        }
        return {};
    }
};

// ============================================================
// 12. CRTP (Curiously Recurring Template Pattern)
// ============================================================
template <typename Derived>
class Comparator {
public:
    bool operator<(const Derived& other) const {
        return static_cast<const Derived*>(this)->lessThan(other);
    }
};

class Point : public Comparator<Point> {
    int x, y;
public:
    Point(int x, int y) : x(x), y(y) {}
    bool lessThan(const Point& other) const {
        return (x + y) < (other.x + other.y);
    }
    int getX() const { return x; }
    int getY() const { return y; }
};

// ============================================================
// 13. MAIN DEMO
// ============================================================
int main() {
    std::cout << "=== atom_flt C++ Demo ===\\n\\n";

    // Shapes
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(5.0));
    shapes.push_back(std::make_unique<Rectangle>(3.0, 4.0));

    for (const auto& s : shapes) {
        std::cout << s->getName() << " area = " << s->area() << "\\n";
        s->draw();
        std::cout << "\\n";
    }

    std::cout << "Total shapes: " << Shape::getTotalShapes() << "\\n\\n";

    // Templates
    Box<int> intBox(42);
    Box<double> dblBox(3.14);
    std::cout << "intBox + dblBox = "
              << (intBox + dblBox).get() << "\\n\\n";

    // Lambdas & algorithms
    std::vector<int> data = {1, 2, 3, 4, 5, 6, 7, 8};
    auto processed = processVector(data);
    std::cout << "Processed: ";
    for (int x : processed) std::cout << x << " ";
    std::cout << "\\n\\n";

    // Variadic
    std::cout << "sumAll: " << sumAll(1, 2, 3, 4, 5) << "\\n";
    printAll("hello", 42, 3.14, "world");

    // Compile-time
    std::cout << "10! = " << compileTimeFactorial << "\\n\\n";

    parallelWork();

    return 0;
}''';

  static const dart = '''import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' show Random;

// ============================================================
// 1. CLASE CON MIXIN
// ============================================================
mixin JsonSerializable {
  Map<String, dynamic> toJson();
}

mixin Loggable {
  void log(String message) {
    print('[LOG] $message');
  }
}

class User with JsonSerializable, Loggable {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

// ============================================================
// 2. GENERICS
// ============================================================
class Result<T> {
  final T? data;
  final String? error;
  final bool get isSuccess => error == null;

  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

// ============================================================
// 3. STREAMS Y FUTURES
// ============================================================
Stream<int> numberStream(int max) async* {
  for (int i = 1; i <= max; i++) {
    await Future.delayed(const Duration(milliseconds: 100));
    yield i;
  }
}

Future<int> fetchData() async {
  await Future.delayed(const Duration(seconds: 1));
  return Random().nextInt(100);
}

// ============================================================
// 4. COLLECTIONS
// ============================================================
class CollectionDemo {
  static void demonstrate() {
    final list = [1, 2, 3, 4, 5];
    final map = {'a': 1, 'b': 2, 'c': 3};
    final set = {1, 2, 3, 4, 5};

    final doubled = list.map((e) => e * 2).toList();
    final even = list.where((e) => e.isEven).toList();

    final result = list.fold<int>(0, (sum, e) => sum + e);
    print('Sum: $result');
  }
}

// ============================================================
// 5. EXTENSION METHODS
// ============================================================
extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  int? toIntOrNull() => int.tryParse(this);
}

// ============================================================
// 6. SEALED CLASS (Dart 3)
// ============================================================
sealed class NetworkState {}

class Loading extends NetworkState {}
class Success extends NetworkState {
  final String data;
  Success(this.data);
}
class Error extends NetworkState {
  final String message;
  Error(this.message);
}

String handleState(NetworkState state) => switch (state) {
      Loading() => 'Loading...',
      Success(data: var d) => 'Success: $d',
      Error(message: var m) => 'Error: $m',
    };

// ============================================================
// 7. RECORDS Y PATTERN MATCHING (Dart 3)
// ============================================================
(String, int) createPerson() => ('Alice', 30);

void recordDestructuring() {
  final (name, age) = createPerson();
  print('$name is $age years old');
}

// ============================================================
// 8. SINGLETON PATTERN
// ============================================================
class Database {
  Database._internal();
  static final Database instance = Database._internal();

  Future<void> connect() async {
    print('Connected to database');
  }
}

// ============================================================
// 9. OBSERVER PATTERN
// ============================================================
class EventBus {
  final _handlers = <String, List<void Function(Map<String, dynamic>)>>{};

  void on(String event, void Function(Map<String, dynamic>) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  void emit(String event, Map<String, dynamic> data) {
    _handlers[event]?.forEach((h) => h(data));
  }
}

// ============================================================
// 10. ASYNC GENERATOR
// ============================================================
Stream<String> readFileLines(String path) async* {
  final file = File(path);
  final lines = file.openRead().transform(utf8.decoder);
  await for (final line in lines.transform(const LineSplitter())) {
    yield line;
  }
}

// ============================================================
// 11. MAIN
// ============================================================
void main() async {
  print('=== atom_flt Dart Demo ===\\n');

  // User with mixins
  final user = User(id: 1, name: 'Alice', email: 'alice@example.com');
  user.log('User created: ${user.toJson()}');

  // Generics
  final result = Result<int>.success(42);
  if (result.isSuccess) {
    print('Result: ${result.data}');
  }

  // Collections
  CollectionDemo.demonstrate();

  // Extension methods
  print('hello world'.capitalize());
  print('42'.toIntOrNull());

  // Sealed class
  print(handleState(Success('done!')));

  // Records
  recordDestructuring();

  // Streams
  await for (final n in numberStream(3)) {
    print('Stream: $n');
  }

  // Event bus
  final bus = EventBus();
  bus.on('user.login', (data) => print('Login: ${data['user']}'));
  bus.emit('user.login', {'user': 'Alice'});
}''';
}

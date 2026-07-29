# **`Subprogram Parameter Passing Implementation`**

**`De La Salle University – Computer Science Department`**

**`Group Members:`**

1. `Neil Jr. Gutang - Rust`  
2. `Allisha Kate Wong - JavaScript`  
3. `Winelle Tolentino - Kotlin`  
4. `Joseph Edward Kelvin Degullado - R`

## **`Part 1: Assignment Guidelines`**

`This assignment focuses on understanding how subprogram parameter passing can be implemented by looking at the four programming languages highlighted for this course: Kotlin, Ruby, R, and Go.`

**`Grading & Submission Details:`**

* `This is a group assignment based on your MCO groupings. One submission will count for everyone in the group.`  
* `Grading will be done individually.`  
* `Each member must commit to only one programming language and answer all questions associated with that language.`  
* `If there are four members in the group, all 4 languages should have answers. (If there are fewer members, adjust the number of languages accordingly).`

**`The Objective:`**

`Investigate the parameter-passing techniques used by your assigned language. Provide examples and explanations that support the usage of each technique the language supports.`

`Recall the five main ways to pass data through the parameters of a subprogram:`

* `Pass by value`  
* `Pass by result`  
* `Pass by value-result`  
* `Pass by reference`  
* `Pass by name`

*`Note: Languages may not implement the exact textbook definition of these methods. Your job is to explain how they behave in practice, similar to the reference example below.`*

## **`Part 2: Reference Example`**

### **`Language: Java`**

### **`Supported Parameter Passing Methods:`**

* `Pass-by-value (only)`  
* `Pass-by-reference (by effect)`

`All primitive typed parameters, like int or double, are pass-by-value. The value of an actual parameter is copied over into the value of the formal parameter. For example, the following method:`

`Java`

```java
public void myMethod(int i) {
    i = 4;
    System.out.println(i); // Outputs 4
}
```

`When used in the following code:`

`Java`

```java
int x = 1;
myMethod(x);
System.out.println(x); // Outputs 1
```

`The value of x (i.e., 1) is copied over to the value of i. Inside myMethod, 4 will be output. In the main code, 1 will be output as the assignment of 4 to i does not affect x. Hence, pass-by-value is achieved.`

`On the other hand, pass-by-reference is a little more complicated to explain as Java only supports pass-by-value. To illustrate the complication, we use the following code as a reference:`

`Java`

```java
public class MyClass {
    private int id;

    public MyClass(int id) {
        this.id = id;
    }

    public int getId() {
        return this.id;
    }

    public void setId(int id) {
        this.id = id;
    }
}

public void myMethod1(MyClass mcParam) {
    mcParam.setId(10);
}

public void myMethod2(MyClass mcParam) {
    mcParam = new MyClass(2);
}
```

`In the code above, we defined a MyClass class that maintains an ID variable to help prove the point that Java is strictly pass-by-value and only implements pass-by-reference as an effect. First, let's take into consideration the following code:`

`Java`

```java
MyClass mc = new MyClass(1);
myMethod1(mc);
System.out.println(mc.getId()); // Outputs 10
```

`With this, we modify the ID attribute of mc from 1 to 10. With this description in mind, it is easy to think that this is indeed pass-by-reference because mc contains an address/reference to a MyClass heap variable, and passing mc to mcParam assigns mcParam the address/reference of mc. Using mcParam, we can modify attributes in the heap variable—which is also being referenced by mc. Hence, we achieve pass-by-reference as an effect.`

`However, this example is more accurately an example of pass-by-value than pass-by-reference because any assignment to the mcParam variable does not affect the value in mc. Both mcParam and mc point to the same heap variable, but mcParam (as the formal parameter) does not affect mc (as the actual parameter).`

`It is said that Java is not truly pass-by-reference because even in instances when an object reference is being passed to a formal parameter, the value in the actual parameter is simply copied into the formal parameter (i.e., the address value is copied). To further illustrate the assertion, we’ll use the following code as a reference:`

`Java`

```java
MyClass mc = new MyClass(1);
myMethod2(mc);
System.out.println(mc.getId()); // Outputs 1
```

`With this code, we see that mc is assigned the address of a MyClass instance with an ID value of 1. When calling myMethod2, the value of mc is copied into mcParam. Once entering myMethod2, mcParam is assigned the address of a new MyClass instance with an ID value of 2. This assignment does not affect the variable mc, so when mc.getId() is called, the output will still be 1. Modifications to the formal parameter do not affect the actual parameter.`

`At this point, it is important to recognize that we are dealing with two separate variables when dealing with objects in Java:`

1. `The reference type variable found in the stack. This variable’s value is the address of an object variable.`  
2. `The object variable found in the heap.`

`If true pass-by-reference were implemented in the Java example where myMethod2 was used, then mcParam should receive the address/reference of its respective actual parameter (i.e., mc). Instead of mcParam receiving the address/reference of mc, it receives the value of mc, which happens to be a reference to a MyClass heap variable. While Java is pass-by-value only, it does achieve the behavior of pass-by-reference thanks to objects being referenced by reference type variables.`

---

## **`Part 3: Group Work Implementation`**

*`(Use the template below for each language you are investigating.)`*

### **`Language: Kotlin`**

**`Supported Parameter Passing Methods:`**

* `Pass-by-value (Strictly)`  
* `Pass-by-reference (By effect with mutable objects/wrapper types)`

**`Explanation and Examples:`**

`Kotlin is strictly a pass-by-value language at the language/memory level. When passing an argument into a function, Kotlin copies the value of that variable into the function’s parameter. What that value actually is depends on whether you’re dealing with a primitive type or an object. For primitive types (Int, Double, Boolean etc.), the actual value itself is copied. Reassigning the parameter inside the function has no effect on the original variable.` 

```kotlin
fun myMethod(i: Int) {
    var localI = i
    localI = 4
    println(localI) // Outputs 4
}

fun main() {
    val x = 1
    myMethod(x)
    println(x) // Outputs 1
}
```

`Function parameters are val by default. They are immutable within the function body. You reassign i directly inside myMethod; you’d need to copy it to a local var first, as shown in the code blocks above.` 

`For object types (including String, custom classes, collections etc.), what gets copied is the reference to an object rather than the object itself. This means the parameter and the original variable point to the same object on the heap. If you mutate the object’s internal state through the parameter, that change is visible through the original variable, producing the effect of pass-by-reference.`

```kotlin
class Box(var value: Int)

fun modifyBox(b: Box) {
    b.value = 4
}

fun main() {
    val myBox = Box(1)
    modifyBox(myBox)
    println(myBox.value) // Outputs 4
}
```

`In the code snippet above, the reference to myBox is copied by value into b. Both b and myBox point to the same Box distance. Mutating the b.value mutates the shared object, as seen in the change within main. Reassigning the parameter to point to a new object entirely does not affect the original variable’s reference, because only the reference’s value was copied and not a link back to the variable itself.` 

```kotlin
fun tryReassign(b: Box) { // b = Box(99) // Compile error: val cannot be reassigned } 
```

`Kotlin prevents the event above by making parameters immutable (val) by default. This makes the user unable to reassign the reference, only allowing one to mutate the object it points to if said object is mutable.` 

`For cases where true reference-style reassignment is needed, Kotlin provides wrapper mechanisms rather than a native &/ref keyword.` 

```kotlin
fun increment(counter: IntArray) {
    counter[0] += 1
}

fun main() {
    val counter = intArrayOf(5)
    increment(counter)
    println(counter[0]) // Outputs 6
}
```

`An array is itself an object, so passing it follows the same reference-copy rule wherein mutating its contents through the parameter mutates the original.`

`Overall, Kotlin has no true pass-by-reference at the memory architecture level. The value copied into a parameter is either a primitive value or an object reference. Since object references let you reach back into shared heap data, Kotlin achieves the practical effect of pass-by-reference whenever mutable objects are involved,  conceptually identical to how Java behaves.`

### **`Language: R`**

**`Supported Parameter Passing Methods:`**

* `Pass-by-value (Strictly, with Copy-on-Write optimization)`  
* `Pass-by-sharing / Pass-by-reference (By effect, using Environments)`

**`Explanation and Examples:`**

`At its core, R functions strictly use pass-by-value. When an argument is passed into a function, R creates a local copy of that variable inside the function. Any modifications made to this parameter do not affect the original variable outside the function. To optimize memory performance, R uses a "copy-on-write" mechanism which means an actual duplicate in memory is only created if the function attempts to modify the data.`  

`For basic data types (like vectors, scalars, or lists), the pass-by-value behavior is straightforward. Modifying the formal parameter inside the function has no effect on the actual parameter.`

```

myMethod <- function(i) {
  i <- 4
  print(i) # This outputs 4
}

x <- 1
myMethod(x)
print(x) # This outputs 1
```

`In this example, the value of x (1) is passed to the parameter i. Assigning 4 to i inside the function does not change x because they point to independent values in memory once a modification occurs.` 

`To achieve a pass-by-reference effect similar to objects in JavaScript or Java, R utilizes a special mutable data type called an Environment. When you pass an environment object to a function, R still passes it by value, but the value being copied is the underlying memory reference to that environment. This behavior functions identically to pass-by-sharing.`

```
modifyObject <- function(envParam) {
  envParam$id <- 10
}

myObj <- new.env()
myObj$id <- 1
modifyObject(myObj)
print(myObj$id) # This outputs 10
```

`In the code above, myObj holds an environment reference where id is 1. When passed to modifyObject, that reference address is copied into envParam. Both variables now point to the exact same environment in memory, updating the internal property through envParam$id directly mutates the original object.`

`However, R is not a true pass-by-reference. If you reassign the formal parameter itself to a brand-new environment object, it breaks the link and leaves the original variable outside the function untouched:`

```
reassignObject <- function(envParam) {
  envParam <- new.env()
  envParam$id <- 2
}

myObj <- new.env()
myObj$id <- 1
reassignObject(myObj)
print(myObj$id) # This outputs 1
```

`If we base on the given code, entering reassignObject, envParam initially points to the same environment as myObj. However, the statement envParam <- new.env() allocates a new environment and updates envParam to point to it. This breaks its connection to myObj. Therefore the reference itself was copied by value, myObj in the calling environment remains unchanged and continues to output 1.`

### **`Language: Rust`**

**`Supported Parameter Passing Methods:`**

* `Pass-by-value (Strictly)`  
* `Pass-by-reference (By effect, via borrowing)`

**`Explanation and Examples:`**

`Strictly speaking, Rust is an exclusively pass-by-value language. Whenever you pass a variable into a function, the bits of that variable on the stack are copied into the function's formal parameter. However, how this behaves in practice depends heavily on Rust’s unique ownership model, which divides behavior into three categories: Copy, Move, and Borrow.`

`For primitive data types (like i32 or f64), Rust implements a Copy trait. When these are passed to a function, their values are directly copied, behaving exactly like traditional pass-by-value.`

```rust
fn my_method(mut i: i32) {
    i = 4;
    println!("{}", i); // Outputs 4
}

fn main() {
    let x = 1;
    my_method(x);
    println!("{}", x); // Outputs 1
}
```

`In this example, the value of x (1) is copied to i. Changing i to 4 inside my_method has no effect on x in the main function.`

`However, for complex types stored on the heap (like a String), passing a variable by value triggers a Move. The stack data (pointer, capacity, and length) is copied by value to the new parameter, but the ownership of the heap data is transferred.`

```rust
fn take_ownership(s: String) {
    println!("{}", s); 
} // s goes out of scope here and the heap memory is freed

fn main() {
    let my_string = String::from("Hello");
    take_ownership(my_string);
    println!("{}", my_string); // This line would cause a compile error!
}
```

`Here, the value of my_string is passed by value into s, but because ownership is moved, my_string becomes completely invalid in the main function after the call.`

`To achieve the effect of pass-by-reference, Rust uses a concept called borrowing, allowing you to pass a reference (&T or &mut T).`

```rust
fn modify_string(s_param: &mut String) {
    s_param.push_str(" World");
}

fn main() {
    let mut my_string = String::from("Hello");
    modify_string(&mut my_string);
    println!("{}", my_string); // Outputs "Hello World"
}
```

`In this case, &mut my_string creates a mutable reference. When passed to modify_string, the reference itself is passed by value (copied into s_param), but because it points to the original heap data, we can modify my_string.`

`Just like Java, Rust does not have true pass-by-reference at the memory architecture level, because the reference itself is copied into the function's local scope. However, by explicitly passing mutable references, Rust safely achieves the exact behavior and effect of pass-by-reference.`

### **`Language: JavaScript`**

**`Supported Parameter Passing Methods:`**

* `Pass-by-value (Strictly)`  
* `Pass-by-sharing / Pass-by-value-of-reference (By effect, for objects)`

**`Explanation and Examples:`**

`JavaScript is strictly a pass-by-value language. When you pass an argument to a function, the value stored in that variable is copied into the function's formal parameter. However, the behavior differs in practice depending on whether you are passing a primitive type or an object type.`

`For primitive data types (such as Number, String, Boolean, null, undefined, and Symbol), the actual value is copied directly on the stack. Modifying the formal parameter inside the function has no effect on the original variable outside the function.`

```javascript
function myMethod(i) {
    i = 4;
    console.log(i); // Outputs 4
}

let x = 1;
myMethod(x);
console.log(x); // Outputs 1
```

`In this example, the value of x (1) is copied over to the parameter i. Assigning 4 to i inside the function does not change x because they occupy different locations in memory. Thus, standard pass-by-value is clear.`

`For object types (including arrays, functions, and standard objects), JavaScript still uses pass-by-value, but the value being copied is the memory address (the reference) of the object on the heap. This specific behavior is frequently referred to as pass-by-sharing.`

`To illustrate how this achieves a pass-by-reference effect, consider the following example:`

```javascript
function modifyObject(objParam) {
    objParam.id = 10;
}

let myObj = { id: 1 };
modifyObject(myObj);
console.log(myObj.id); // Outputs 10
```

`Here, myObj holds the memory address of the object { id: 1 }. When myObj is passed to modifyObject, that address value is copied into objParam. Because both variables point to the exact same object in the heap, modifying properties via objParam.id directly mutates the original object. This creates the effect of pass-by-reference.`

`However, JavaScript is not true pass-by-reference. If you reassign the formal parameter itself to an entirely new object, it does not affect the actual parameter outside the function:`

```javascript
function reassignObject(objParam) {
    objParam = { id: 2 };
}

let myObj = { id: 1 };
reassignObject(myObj);
console.log(myObj.id); // Outputs 1
```

`When entering reassignObject, objParam initially points to the same object as myObj. However, the assignment objParam = { id: 2 } changes the address stored inside objParam to point to a completely new object in the heap. This breaks its connection to myObj. Because the reference itself was passed by value (copied), the variable myObj in the calling environment remains completely unchanged, continuing to output 1. Therefore, while JavaScript is strictly pass-by-value, it achieves the operational characteristics of pass-by-reference for complex types through reference-sharing.`


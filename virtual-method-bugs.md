# Virtual Method Bugs in C#

## Question: What kind of bugs can changing a method to `virtual` cause?

Changing a method to `virtual` flips it from “always call this body” to “someone else might hijack this call.” That opens a bunch of subtle failure modes:

1. **Accidental overrides start running**  
   Any derived class (including test doubles) with an `override` now changes behavior. Invariants the base method enforced can be skipped, pre/post-conditions can be loosened, and thread-safety can be broken.  
   If you (or a library) call the method through a base reference, you’ll now get the derived override—sometimes not what your tests expected.

2. **The “fragile base class” problem**  
   The base implementation may assume certain internal state has been set or that operations happen in a certain order. An override that forgets to call `base.Foo()` or changes ordering can break those assumptions.

3. **Virtual call in constructors/initializers**  
   If the base type calls the (now virtual) method in its constructor or in field initializers, the override runs **before** the derived constructor finishes. That can hit uninitialized fields/nulls in the derived type and explode.

4. **Method hiding becomes a landmine (`new` vs `override`)**  
   If a derived class already had a same-signature method using `new`, it *still* hides rather than overrides. Calls via a `Derived` variable hit the hidden method; calls via a `Base` variable hit the base virtual. That split dispatch can make tests behave inconsistently.

5. **Dynamic proxies start intercepting**  
   Libraries that use proxying (Castle DynamicProxy, Moq, NSubstitute, EF Core lazy loading) can now intercept the method because it’s virtual. In tests, a mock might unexpectedly stub or intercept calls, changing return values, timing, or side-effects your tests relied on.

6. **Serialization/proxy quirks**  
   EF Core lazy loading requires virtual navigation members; making something virtual can suddenly enable lazy loading and change query shapes or database access patterns in tests.

7. **Performance/timing differences**  
   The JIT will eagerly inline non-virtual, `sealed`, and `private` methods. Making it virtual can block inlining and devirtualization, shifting timing.

8. **Contract drift with optional parameters**  
   Optional parameter defaults are bound at compile time. If an override uses different defaults, calls through a **base**-typed reference will still use the base defaults, while derived-typed calls use the derived defaults.

9. **Reflection/analysis code changes**  
   Anything checking `MethodInfo.IsVirtual` or building dynamic dispatch tables may treat the method differently now.

---

## Follow-up: Mocking frameworks intercepting methods

Changing a method to `virtual` could cause mocking frameworks like Moq to unintentionally mock methods, returning defaults instead of running the real code.

### Ways to fix:

1. **Call the base implementation by default**
```csharp
var mock = new Mock<MyClass>() { CallBase = true };
```
Or per member:
```csharp
mock.Setup(m => m.Save()).CallBase();
```

2. **Mock an interface instead of the class**
```csharp
public interface IMyService { int Compute(int x); }
public class MyService : IMyService { public virtual int Compute(int x) { ... } }

var mock = new Mock<IMyService>();
```

3. **Strict mode + verification**
```csharp
var mock = new Mock<MyClass>(MockBehavior.Strict) { CallBase = true };
mock.VerifyNoOtherCalls();
```

4. **Don’t mock the class at all**  
   Prefer mocking dependencies.

5. **Seal specific overrides**
```csharp
public class MyClass_NoOverride : MyClass {
    public sealed override void Save() => base.Save();
}
```

6. **Watch out for constructor pitfalls**  
   If the virtual is called in a constructor, mocks can run it before initialization.

---

**Triage path**:  
1. Add `CallBase = true` to mocks.  
2. Use `Strict` mode and verify no other calls.  
3. Long term: extract interfaces and mock collaborators, not the concrete SUT.

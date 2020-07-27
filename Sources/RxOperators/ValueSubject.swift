//
//  ValueSubject.swift
//  RxOperators
//
//  Created by Daniil on 10.08.2019.
//

import Foundation
import RxSwift
import RxCocoa

@dynamicMemberLookup
@propertyWrapper
public final class ValueSubject<Element>: DisposableObservableType, DisposableObserverType {
    
    public var value: Element {
        get { wrappedValue }
        set { wrappedValue = newValue }
    }
    public var projectedValue: ValueSubject<Element> { self }
    public var wrappedValue: Element {
        get { return lock.protect { val } }
        set {
            setValue(newValue)
            publishSubject.onNext(newValue)
        }
    }
    private let disposeBag: DisposeBag
    private let lock = NSRecursiveLock()
    @Value private var val: Element
    private let publishSubject = PublishSubject<Element>()
    
    public convenience init(wrappedValue initialValue: Element) {
        self.init(wrappedValue: initialValue, bag: DisposeBag())
    }
    
    public convenience init(wrappedValue initialValue: Element, bag: DisposeBag) {
        self.init(.wrap(initialValue), bag: bag)
    }
    
    fileprivate init(_ value: Value<Element>, bag: DisposeBag) {
        _val = value
        disposeBag = bag
    }
    
    public convenience init(_ value: Element) {
        self.init(wrappedValue: value)
    }
    
    @discardableResult
    public func subscribe<O: ObserverType>(_ observer: O) -> Disposable where Element == O.Element {
        let result = publishSubject.subscribe(observer)
        insert(disposable: result)
        observer.onNext(wrappedValue)
        return result
    }
    
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Element, T>) -> ValueSubject<T> {
        ValueSubject<T>(
            Value<T>(
                get: { self.wrappedValue[keyPath: keyPath] },
                set: {
                    var val = self.val
                    val[keyPath: keyPath] = $0
                    self.wrappedValue = val
                }),
            bag: disposeBag
        )
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> Observable<T> {
        self.map { $0[keyPath: keyPath] }
    }
    
    public func asNotSharing() -> AnyObserver<Element> {
        return AnyObserver {[weak self] in
            guard case .next(let newValue) = $0 else { return }
            self?.setValue(newValue)
        }
    }
    
    public func on(_ event: Event<Element>) {
        guard case .next(let newValue) = event else { return }
        wrappedValue = newValue
    }
    
    public func insert(disposable: Disposable) {
        disposeBag.insert(disposable)
    }
    
    private func setValue(_ newValue: Element) {
        lock.protect { val = newValue }
    }
    
}

extension ValueSubject: Decodable where Element: Decodable {
    
    public convenience init(from decoder: Decoder) throws {
        try self.init(Element(from: decoder))
    }
    
}

extension ValueSubject: Encodable where Element: Encodable {
    
    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
    
}

@propertyWrapper
fileprivate struct Value<T> {
    let get: () -> T
    let set: (T) -> ()
    static func wrap(_ value: T) -> Value {
        var val = value
        return Value(get: { val }, set: { val = $0 })
    }
    var wrappedValue: T {
        get { get() }
        set { set(newValue) }
    }
}

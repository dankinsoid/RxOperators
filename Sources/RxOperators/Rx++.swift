//
//  Rx++.swift
//  MusicImport
//
//  Created by Данил Войдилов on 21.06.2019.
//  Copyright © 2019 Данил Войдилов. All rights reserved.
//


import Foundation
import RxSwift
import RxCocoa
import VDKit

extension PrimitiveSequenceType where Self.Trait == SingleTrait {
	
	public func subscribe(_ completion: @escaping (Result<Self.Element, Error>) -> ()) -> Disposable {
		return self.subscribe(
			onSuccess: { completion(.success($0)) },
			onError: { completion(.failure($0)) }
		)
	}
	
}

extension NSNotification.Name {
	
	public var rx: Observable<Notification> {
		return NotificationCenter.default.rx.notification(self)
	}
	
}

extension ObservableType where Element: OptionalProtocol {
	
	public func skipNil() -> Observable<Element.Wrapped> {
		return map({ $0.asOptional() }).filter({ $0 != nil }).map({ $0! })
	}
	
}

extension ObservableType where Element == Bool? {
	
	public func or(_ value: Bool) -> Observable<Bool> {
		return map({ $0 ?? value })
	}
	
}

extension ObservableType where Element == Bool {
	
	public func toggle() -> Observable<Bool> {
		return map({ !$0 })
	}
	
}

extension ObservableType {
	
	public func asDriver() -> Driver<Element> {
		return asDriver(onErrorDriveWith: .never())
	}
	
}

public struct WeakRef<T: AnyObject, Element>: ObserverType {
	public weak var object: T?
	public let keyPath: ReferenceWritableKeyPath<T, Element>
	
	public func on(_ event: Event<Element>) {
		if case .next(let value) = event {
			object?[keyPath: keyPath] = value
		}
	}
	
}

public struct WeakMethod<T: AnyObject, Element>: ObserverType {
	public weak var object: T?
	public let method: (T) -> (Element) -> ()
	
	public func on(_ event: Event<Element>) {
		if let obj = object, case .next(let value) = event {
			method(obj)(value)
		}
	}
	
}

extension Reactive where Base: AnyObject {
	
	public func keyPath<Element>(_ keyPath: ReferenceWritableKeyPath<Base, Element>) -> AnyObserver<Element> {
		return WeakRef(object: base, keyPath: keyPath).asObserver()
	}
	
	public func weak<E>(method: @escaping (Base) -> (E) -> ()) -> AnyObserver<E> {
		return WeakMethod(object: base, method: method).asObserver()
	}
	
	public func weak(method: @escaping (Base) -> () -> ()) -> AnyObserver<Void> {
		return WeakMethod(object: base, method: { b in {_ in method(b)() } }).asObserver()
	}
	
}

extension ObservableType {
	
	public func map<B: AnyObject, T>(_ method:  @escaping (B) -> (Element) -> T, on object: B) -> Observable<T> {
		return compactMap {[weak object] in
			guard let obj = object else { return nil }
			return method(obj)($0)
		}
	}
	
}

extension PrimitiveSequenceType where Trait == SingleTrait {
	
	public func await() throws -> Element {
		var e: Element?
		var err: Error?
		let semaphore = DispatchSemaphore(value: 0)
		var d: Disposable?
		DispatchQueue.global().async {
			d = self.primitiveSequence.asObservable().subscribe { (event) in
				switch event {
				case .next(let element):
					e = element
				case .error(let error):
					err = error; semaphore.signal()
				case .completed: semaphore.signal()
				}
			}
		}
		semaphore.wait()
		d?.dispose()
		if let er = err {
			throw er
		} else if e == nil {
			throw RxError.noElements
		}
		return e!
	}
	
}

extension ObservableType {
	
	public func interval(_ period: DispatchTimeInterval, scheduler: SchedulerType) -> Observable<Element> {
		let observable = asObservable()
		return Observable.zip(
			observable,
			Observable.merge(Observable<Int>.interval(period, scheduler: scheduler), Observable.just(0))
		).map({ $0.0 })
	}
	
	public func withLast(initialValue value: Element) -> Observable<(previous: Element, current: Element)> {
		return asObservable().scan((value, value), accumulator: { ($0.1, $1) })
	}
	
	public func withLast() -> Observable<(previous: Element?, current: Element)> {
		return asObservable().scan((nil, nil), accumulator: { ($0.1, $1) }).map({ ($0.0, $0.1!) })
	}
	
}

extension Reactive where Base: NSObject {
	
	func observe<T>(_ keyPath: KeyPath<Base, T>) -> Observable<T> {
		return Observable.create {[weak base] observer in
			guard let base = base else { return Disposables.create() }
			observer.onNext(base[keyPath: keyPath])
			let observation = base.observe(keyPath) { (_, change) in
				if let value = change.newValue { observer.onNext(value) }
			}
			return Disposables.create {
				observation.invalidate()
			}
		}
	}
	
}

fileprivate final class Ref<T> {
	var value: T
	init(_ value: T) { self.value = value }
}

extension RxTimeInterval {
	public var seconds: TimeInterval? {
		switch self {
		case .seconds(let result):      return TimeInterval(result)
		case .milliseconds(let result): return TimeInterval(result) * 1_000
		case .microseconds(let result): return TimeInterval(result) * 1_000_000
		case .nanoseconds(let result):  return TimeInterval(result) * 1_000_000_000
		case .never:                    return nil
		@unknown default:								return nil
		}
	}
}

@dynamicMemberLookup
public struct RxPropertyMapper<Base: ObservableType, Element>: ObservableType {
	private let base: Base
	private let keyPath: KeyPath<Base.Element, Element>
	
	fileprivate init(_ base: Base, for keyPath: KeyPath<Base.Element, Element>) {
		self.base = base
		self.keyPath = keyPath
	}
	
	public subscript<T>(dynamicMember keyPath: KeyPath<Element, T>) -> RxPropertyMapper<Base, T> {
		return RxPropertyMapper<Base, T>(base, for: self.keyPath.appending(path: keyPath))
	}
	
	public func subscribe<Observer: ObserverType>(_ observer: Observer) -> Disposable where Element == Observer.Element {
		let kp = keyPath
		return base.map({ $0[keyPath: kp] }).subscribe(observer)
	}
	
}

extension ObservableType {
	public var mp: RxPropertyMapper<Self, Element> { RxPropertyMapper(self, for: \.self) }
}

extension ObservableType {
	
	public func map<T>(_ keyPath: KeyPath<Element, T>) -> Observable<T> {
		map { $0[keyPath: keyPath] }
	}
	
	public func value<T>(_ value: T) -> Observable<T> {
		map { _ in value }
	}
	
}

extension Reactive where Base: AnyObject {
	
	public var asDisposeBag: DisposeBag {
		if let dispose = objc_getAssociatedObject(base, &disposeBagKey) as? DisposeBag { return dispose }
		let dispose = DisposeBag()
		objc_setAssociatedObject(base, &disposeBagKey, dispose, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		return dispose
	}
	
}

fileprivate var disposeBagKey = "ReactiveDisposeBagKey"

extension ObservableType where Element: Collection {
	
	public func skipEqualSize() -> Observable<Element> {
		distinctUntilChanged { $0.count == $1.count }
	}
	
}

extension ObserverType where Element == Void {
	
	public func onNext() {
		onNext(())
	}
	
}

extension ObservableType {
	
	public func asResult() -> Observable<Result<Element, Error>> {
		Observable.create { observer in
			self.subscribe { event in
				switch event {
				case .next(let element):
					observer.onNext(.success(element))
				case .error(let error):
					observer.onNext(.failure(error))
				case .completed:
					observer.onCompleted()
				}
			}
		}
	}
	
}

extension ObservableConvertibleType where Element: Collection {
	public var nilIfEmpty: Observable<Element?> { asObservable().map { $0.isEmpty ? nil : $0 } }
	public var isEmpty: Observable<Bool> { asObservable().map { $0.isEmpty } }
}

extension ObservableConvertibleType where Element: OptionalProtocol {
	public var isNil: Observable<Bool> { asObservable().map { $0.asOptional() == nil } }
}

extension ObservableConvertibleType where Element: OptionalProtocol, Element.Wrapped: Collection {
	public var isNilOrEmpty: Observable<Bool> { asObservable().map { $0.asOptional()?.isEmpty != false } }
}

extension ObservableType where Element: Equatable {
	public func skipEqual() -> Observable<Element> { distinctUntilChanged() }
}

extension Observable {
	
	public static func from(_ array: Element...) -> Observable {
		Observable.from(array)
	}
	
}

extension PrimitiveSequence where Trait == SingleTrait {
	
	public static func wrap<Failure: Error>(_ function: @escaping (@escaping (Result<Element, Failure>) -> Void) -> Void) -> Single<Element> {
		create { block -> Disposable in
			function {
				switch $0 {
				case .failure(let error):
					block(.error(error))
				case .success(let element):
					block(.success(element))
				}
			}
			return Disposables.create()
		}
	}
	
	public static func wrap<A, Failure: Error>(_ function: @escaping (A, @escaping (Result<Element, Failure>) -> Void) -> Void, value: A) -> Single<Element> {
		wrap { function(value, $0) }
	}
	
	public static func wrap<A, B, Failure: Error>(_ function: @escaping (A, B, @escaping (Result<Element, Failure>) -> Void) -> Void, _ value1: A, _ value2: B) -> Single<Element> {
		wrap { function(value1, value2, $0) }
	}
	
	public static func wrap<A, B, C, Failure: Error>(_ function: @escaping (A, B, C, @escaping (Result<Element, Failure>) -> Void) -> Void, _ value1: A, _ value2: B, _ value3: C) -> Single<Element> {
		wrap { function(value1, value2, value3, $0) }
	}
	
	
	public static func guarantee(_ function: @escaping (@escaping (Element) -> Void) -> Void) -> Single<Element> {
		wrap { completion in function { completion(Result<Element, Never>.success($0)) } }
	}
	
	public static func guarantee<A>(_ function: @escaping (A, @escaping (Element) -> Void) -> Void, value: A) -> Single<Element> {
		guarantee { function(value, $0) }
	}
	
	public static func guarantee<A, B>(_ function: @escaping (A, B, @escaping (Element) -> Void) -> Void, _ value1: A, _ value2: B) -> Single<Element> {
		guarantee { function(value1, value2, $0) }
	}
	
	public static func guarantee<A, B, C>(_ function: @escaping (A, B, C, @escaping (Element) -> Void) -> Void, _ value1: A, _ value2: B, _ value3: C) -> Single<Element> {
		guarantee { function(value1, value2, value3, $0) }
	}
	
	
	public static func wrap<Failure: Error>(_ function: @escaping (@escaping (Element, Failure?) -> Void) -> Void) -> Single<Element> {
		wrap { completion in function { completion(Result(success: $0, failure: $1)) } }
	}
	
	public static func wrap<A, Failure: Error>(_ function: @escaping (A, @escaping (Element, Failure?) -> Void) -> Void, value: A) -> Single<Element> {
		wrap { function(value, $0) }
	}
	
	public static func wrap<A, B, Failure: Error>(_ function: @escaping (A, B, @escaping (Element, Failure?) -> Void) -> Void, _ value1: A, _ value2: B) -> Single<Element> {
		wrap { function(value1, value2, $0) }
	}
	
	public static func wrap<A, B, C, Failure: Error>(_ function: @escaping (A, B, C, @escaping (Element, Failure?) -> Void) -> Void, _ value1: A, _ value2: B, _ value3: C) -> Single<Element> {
		wrap { function(value1, value2, value3, $0) }
	}
	
}

extension ObservableConvertibleType {
	
	public func append(_ values: Element...) -> Observable<Element> {
		asObservable().concat(Observable.from(values))
	}
	
	public func andIsSame<T: Equatable>(_ keyPath: KeyPath<Element, T>) -> Observable<(Element, Bool)> {
		asObservable().withLast().map {
			($0.current, $0.previous?[keyPath: keyPath] == $0.current[keyPath: keyPath])
		}
	}
	
}

extension Result where Failure == Error {
	
	public init(success: Success?, failure: Error?) {
		if let value = success {
			self = .success(value)
		} else {
			self = .failure(failure ?? UnknownError.unknown)
		}
	}
	
}

private enum UnknownError: Error {
	case unknown
}

extension ObservableConvertibleType {
	
	public func throttle(s duration: TimeInterval, scheduler: SchedulerType = MainScheduler.asyncInstance) -> Observable<Element> {
		asObservable().throttle(.milliseconds(Int(duration * 1000)), scheduler: scheduler)
	}
	
	public func throttle(ms duration: Int, scheduler: SchedulerType = MainScheduler.asyncInstance) -> Observable<Element> {
		asObservable().throttle(.milliseconds(duration), scheduler: scheduler)
	}
	
}

extension ClosedRange where Bound: FloatingPoint {
	
	public func split(count: Int) -> [Bound] {
		guard count > 0 else { return [] }
		guard count > 1 else { return [lowerBound] }
		guard count > 2 else { return [lowerBound, upperBound] }
		let delta = (upperBound - lowerBound) / Bound(count)
		var result: [Bound] = []
		result.append(lowerBound)
		for _ in 1..<(count - 1) {
			result.append(result.last! + delta)
		}
		result.append(upperBound)
		return result
	}
	
}

extension ObservableConvertibleType where Element == String {
	
	public func smooth(_ duration: TimeInterval = 0.3, scheduler: SchedulerType = MainScheduler.asyncInstance) -> Observable<Element> {
		let interval: RxTimeInterval = .milliseconds(30)
		return smooth(interval: interval, count: Int(duration / interval.seconds), scheduler: scheduler)
	}
	
	public func smooth(interval: RxTimeInterval, count: Int, scheduler: SchedulerType = MainScheduler.asyncInstance) -> Observable<Element> {
		asObservable()
		.distinctUntilChanged()
		.smooth(
			rule: {
				$0.smooth(to: $1, count: $2)
			},
			interval: interval,
			count: count,
			scheduler: scheduler
		)
	}
	
}

extension String {
	
	func smooth(to: String, count: Int) -> [String] {
		guard count > 2 else { return [self, to].suffix(max(0, count)) }
		guard !to.isEmpty || !isEmpty else {
			return [String](repeating: "", count: count)
		}
		guard to != self else {
			return [String](repeating: to, count: count)
		}
		var result = [self]
		let commonPr = commonPrefix(with: to)
		let commonSfCount = max(0, min(commonSuffix(with: to).count, min(self.count, to.count) - commonPr.count))
		for i in commonPr.count..<(max(self.count, to.count) - commonSfCount) {
			var last = result[result.count - 1]
			if i < last.count, i < to.count {
				last[.first + i] = to[.first + i]
			} else if i < to.count {
				last.append(to[.first + i]!)
			} else if i < last.count {
				_ = last.remove(at: .first + i)
			}
			result.append(last)
		}
		if result.count < count {
			for _ in 0..<(count - result.count) {
				let i = Int.random(in: 0..<result.count)
				result.insert(result[i], at: i)
			}
		} else if count < result.count {
			for _ in 0..<(result.count - count) {
				result.remove(at: .random(in: 0..<result.count))
			}
		}
		result[result.count - 1] = to
		return result
	}
	
}

extension ObservableConvertibleType where Element: FloatingPoint {
	
	public func smooth(_ duration: RxTimeInterval = .seconds(1), scheduler: SchedulerType = MainScheduler.asyncInstance) -> Observable<Element> {
		let interval: RxTimeInterval = .milliseconds(20)
		return smooth(interval: interval, count: Int(duration.seconds / interval.seconds), scheduler: scheduler)
	}
	
	public func smooth(interval: RxTimeInterval, count: Int, scheduler: SchedulerType = MainScheduler.asyncInstance) -> Observable<Element> {
		asObservable()
		.distinctUntilChanged()
		.smooth(
			rule: {
				let isGrow = $0 < $1
				let range = isGrow ? $0...$1 : $1...$0
				return isGrow ? range.split(count: $2) : range.split(count: $2).reversed()
			},
			interval: interval,
			count: count,
			scheduler: scheduler
		)
	}
	
}

extension ObservableConvertibleType {
	
	public func smooth<F: FloatingPoint>(
		_ duration: RxTimeInterval = .seconds(1),
		scheduler: SchedulerType = MainScheduler.asyncInstance,
		float: @escaping (Element) -> F,
		value: @escaping (F, Element) -> Element,
		condition: @escaping (Element, Element) -> Bool = { _, _ in true }
	) -> Observable<Element> {
		let interval: RxTimeInterval = .milliseconds(20)
		return smooth(interval: interval, count: Int(duration.seconds / interval.seconds), scheduler: scheduler, float: float, value: value, condition: condition)
	}
	
	public func smooth<F: FloatingPoint>(interval: RxTimeInterval, count: Int, scheduler: SchedulerType = MainScheduler.asyncInstance, float: @escaping (Element) -> F, value: @escaping (F, Element) -> Element, condition: @escaping (Element, Element) -> Bool = { _, _ in true }) -> Observable<Element> {
		smooth(
			rule: { f, s, count in
				let (first, second) = (float(f), float(s))
				let isGrow = first < second
				let range = isGrow ? first...second : second...first
				return (isGrow ? range.split(count: count) : range.split(count: count).reversed()).map { value($0, s) }
			},
			interval: interval,
			count: count,
			scheduler: scheduler,
			condition: condition
		)
	}
	
}

extension ObservableConvertibleType {
	
	public func smooth(rule: @escaping (Element, Element, Int) -> [Element], interval: RxTimeInterval, count: Int, scheduler: SchedulerType = MainScheduler.asyncInstance, condition: @escaping (Element, Element) -> Bool = { _, _ in true }) -> Observable<Element> {
		asObservable()
			.scan([], accumulator: { $0.suffix(1) + [$1] })
			.flatMap { list -> Observable<Element> in
				guard list.count == 2 else { return .just(list[0]) }
				guard condition(list[0], list[1]) else { return .just(list[1]) }
				let array = rule(list[0], list[1], count)
				return Observable<Int>
					.interval(interval, scheduler: scheduler)
					.take(array.count)
					.map { array[$0] }
			}
	}
	
	public func smooth(rule: @escaping (Element, Element, Int) -> [Element], duration: RxTimeInterval = .seconds(1), scheduler: SchedulerType = MainScheduler.asyncInstance, condition: @escaping (Element, Element) -> Bool = { _, _ in true }) -> Observable<Element> {
		let interval: RxTimeInterval = .milliseconds(20)
		return smooth(rule: rule, interval: interval, count: Int(duration.seconds / interval.seconds), scheduler: scheduler, condition: condition)
	}
	
}

extension ClosedRange where Bound: FloatingPoint {
	
	public func split(count: Int) -> [Bound] {
		guard count > 2 else { return [lowerBound, upperBound].suffix(count) }
		var result: [Bound] = [lowerBound]
		let delta = (upperBound - lowerBound) / Bound(count)
		for _ in 2..<count {
			result.append(result[result.count - 1] + delta)
		}
		result.append(upperBound)
		return result
	}
	
}

extension RxTimeInterval {
	
	public var seconds: TimeInterval {
		switch self {
		case .seconds(let seconds):			return TimeInterval(seconds)
		case .milliseconds(let milli):	return TimeInterval(milli) / 1_000
		case .microseconds(let micro):	return TimeInterval(micro) / 1_000_000
		case .nanoseconds(let nano):		return TimeInterval(nano) / 1_000_000_000
		case .never:										return .infinity
		@unknown default:								return 0
		}
	}
	
}

extension ObservableType {
	
	public func onNext(_ action: @escaping (Element) throws -> Void) -> Observable<Element> {
		self.do(onNext: action)
	}
	
	public func afterNext(_ action: @escaping (Element) throws -> Void) -> Observable<Element> {
		self.do(afterNext: action)
	}
	
	public func onError(_ action: @escaping (Error) throws -> Void) -> Observable<Element> {
		self.do(onError: action)
	}
	
	public func afterError(_ action: @escaping (Error) throws -> Void) -> Observable<Element> {
		self.do(afterError: action)
	}
	
	public func onCompleted(_ action: @escaping () -> Void) -> Observable<Element> {
		self.do(onCompleted: action)
	}
	
	public func afterCompleted(_ action: @escaping () -> Void) -> Observable<Element> {
		self.do(afterCompleted: action)
	}
	
	public func onSubscribe(_ action: @escaping () -> Void) -> Observable<Element> {
		self.do(onSubscribe: action)
	}
	
	public func onSubscribed(_ action: @escaping () -> Void) -> Observable<Element> {
		self.do(onSubscribed: action)
	}
	
	public func onDispose(_ action: @escaping () -> Void) -> Observable<Element> {
		self.do(onDispose: action)
	}
	
	public func `guard`(_ condition: @escaping (Element) throws -> Bool) -> Observable<Element> {
		self.map {
			guard try condition($0) else {
				throw RxError.unknown
			}
			return $0
		}
	}

}

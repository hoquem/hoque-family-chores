// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_creation_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskCreationState {

 bool get isLoading; String? get error; bool get isSuccess;
/// Create a copy of TaskCreationState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCreationStateCopyWith<TaskCreationState> get copyWith => _$TaskCreationStateCopyWithImpl<TaskCreationState>(this as TaskCreationState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskCreationState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,error,isSuccess);

@override
String toString() {
  return 'TaskCreationState(isLoading: $isLoading, error: $error, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class $TaskCreationStateCopyWith<$Res>  {
  factory $TaskCreationStateCopyWith(TaskCreationState value, $Res Function(TaskCreationState) _then) = _$TaskCreationStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String? error, bool isSuccess
});




}
/// @nodoc
class _$TaskCreationStateCopyWithImpl<$Res>
    implements $TaskCreationStateCopyWith<$Res> {
  _$TaskCreationStateCopyWithImpl(this._self, this._then);

  final TaskCreationState _self;
  final $Res Function(TaskCreationState) _then;

/// Create a copy of TaskCreationState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? error = freezed,Object? isSuccess = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskCreationState].
extension TaskCreationStatePatterns on TaskCreationState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskCreationState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskCreationState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskCreationState value)  $default,){
final _that = this;
switch (_that) {
case _TaskCreationState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskCreationState value)?  $default,){
final _that = this;
switch (_that) {
case _TaskCreationState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String? error,  bool isSuccess)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskCreationState() when $default != null:
return $default(_that.isLoading,_that.error,_that.isSuccess);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String? error,  bool isSuccess)  $default,) {final _that = this;
switch (_that) {
case _TaskCreationState():
return $default(_that.isLoading,_that.error,_that.isSuccess);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String? error,  bool isSuccess)?  $default,) {final _that = this;
switch (_that) {
case _TaskCreationState() when $default != null:
return $default(_that.isLoading,_that.error,_that.isSuccess);case _:
  return null;

}
}

}

/// @nodoc


class _TaskCreationState extends TaskCreationState {
  const _TaskCreationState({this.isLoading = false, this.error, this.isSuccess = false}): super._();
  

@override@JsonKey() final  bool isLoading;
@override final  String? error;
@override@JsonKey() final  bool isSuccess;

/// Create a copy of TaskCreationState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCreationStateCopyWith<_TaskCreationState> get copyWith => __$TaskCreationStateCopyWithImpl<_TaskCreationState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskCreationState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.isSuccess, isSuccess) || other.isSuccess == isSuccess));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,error,isSuccess);

@override
String toString() {
  return 'TaskCreationState(isLoading: $isLoading, error: $error, isSuccess: $isSuccess)';
}


}

/// @nodoc
abstract mixin class _$TaskCreationStateCopyWith<$Res> implements $TaskCreationStateCopyWith<$Res> {
  factory _$TaskCreationStateCopyWith(_TaskCreationState value, $Res Function(_TaskCreationState) _then) = __$TaskCreationStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String? error, bool isSuccess
});




}
/// @nodoc
class __$TaskCreationStateCopyWithImpl<$Res>
    implements _$TaskCreationStateCopyWith<$Res> {
  __$TaskCreationStateCopyWithImpl(this._self, this._then);

  final _TaskCreationState _self;
  final $Res Function(_TaskCreationState) _then;

/// Create a copy of TaskCreationState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? error = freezed,Object? isSuccess = null,}) {
  return _then(_TaskCreationState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,isSuccess: null == isSuccess ? _self.isSuccess : isSuccess // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

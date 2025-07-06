// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_summary_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskSummaryState {

 TaskSummaryStatus get status; TaskSummary? get summary; String? get errorMessage; bool get isLoading;
/// Create a copy of TaskSummaryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskSummaryStateCopyWith<TaskSummaryState> get copyWith => _$TaskSummaryStateCopyWithImpl<TaskSummaryState>(this as TaskSummaryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskSummaryState&&(identical(other.status, status) || other.status == status)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,status,summary,errorMessage,isLoading);

@override
String toString() {
  return 'TaskSummaryState(status: $status, summary: $summary, errorMessage: $errorMessage, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $TaskSummaryStateCopyWith<$Res>  {
  factory $TaskSummaryStateCopyWith(TaskSummaryState value, $Res Function(TaskSummaryState) _then) = _$TaskSummaryStateCopyWithImpl;
@useResult
$Res call({
 TaskSummaryStatus status, TaskSummary? summary, String? errorMessage, bool isLoading
});




}
/// @nodoc
class _$TaskSummaryStateCopyWithImpl<$Res>
    implements $TaskSummaryStateCopyWith<$Res> {
  _$TaskSummaryStateCopyWithImpl(this._self, this._then);

  final TaskSummaryState _self;
  final $Res Function(TaskSummaryState) _then;

/// Create a copy of TaskSummaryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? summary = freezed,Object? errorMessage = freezed,Object? isLoading = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskSummaryStatus,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as TaskSummary?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskSummaryState].
extension TaskSummaryStatePatterns on TaskSummaryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskSummaryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskSummaryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskSummaryState value)  $default,){
final _that = this;
switch (_that) {
case _TaskSummaryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskSummaryState value)?  $default,){
final _that = this;
switch (_that) {
case _TaskSummaryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TaskSummaryStatus status,  TaskSummary? summary,  String? errorMessage,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskSummaryState() when $default != null:
return $default(_that.status,_that.summary,_that.errorMessage,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TaskSummaryStatus status,  TaskSummary? summary,  String? errorMessage,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _TaskSummaryState():
return $default(_that.status,_that.summary,_that.errorMessage,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TaskSummaryStatus status,  TaskSummary? summary,  String? errorMessage,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _TaskSummaryState() when $default != null:
return $default(_that.status,_that.summary,_that.errorMessage,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _TaskSummaryState implements TaskSummaryState {
  const _TaskSummaryState({this.status = TaskSummaryStatus.loading, this.summary, this.errorMessage, this.isLoading = false});
  

@override@JsonKey() final  TaskSummaryStatus status;
@override final  TaskSummary? summary;
@override final  String? errorMessage;
@override@JsonKey() final  bool isLoading;

/// Create a copy of TaskSummaryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskSummaryStateCopyWith<_TaskSummaryState> get copyWith => __$TaskSummaryStateCopyWithImpl<_TaskSummaryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskSummaryState&&(identical(other.status, status) || other.status == status)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,status,summary,errorMessage,isLoading);

@override
String toString() {
  return 'TaskSummaryState(status: $status, summary: $summary, errorMessage: $errorMessage, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$TaskSummaryStateCopyWith<$Res> implements $TaskSummaryStateCopyWith<$Res> {
  factory _$TaskSummaryStateCopyWith(_TaskSummaryState value, $Res Function(_TaskSummaryState) _then) = __$TaskSummaryStateCopyWithImpl;
@override @useResult
$Res call({
 TaskSummaryStatus status, TaskSummary? summary, String? errorMessage, bool isLoading
});




}
/// @nodoc
class __$TaskSummaryStateCopyWithImpl<$Res>
    implements _$TaskSummaryStateCopyWith<$Res> {
  __$TaskSummaryStateCopyWithImpl(this._self, this._then);

  final _TaskSummaryState _self;
  final $Res Function(_TaskSummaryState) _then;

/// Create a copy of TaskSummaryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? summary = freezed,Object? errorMessage = freezed,Object? isLoading = null,}) {
  return _then(_TaskSummaryState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskSummaryStatus,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as TaskSummary?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

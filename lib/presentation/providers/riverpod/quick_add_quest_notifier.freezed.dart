// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quick_add_quest_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuickAddQuestState {

 String get title; int get stars; UserId? get assignedToId; DateTime? get dueDate; bool get isSubmitting; String? get errorMessage;
/// Create a copy of QuickAddQuestState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuickAddQuestStateCopyWith<QuickAddQuestState> get copyWith => _$QuickAddQuestStateCopyWithImpl<QuickAddQuestState>(this as QuickAddQuestState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuickAddQuestState&&(identical(other.title, title) || other.title == title)&&(identical(other.stars, stars) || other.stars == stars)&&(identical(other.assignedToId, assignedToId) || other.assignedToId == assignedToId)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,title,stars,assignedToId,dueDate,isSubmitting,errorMessage);

@override
String toString() {
  return 'QuickAddQuestState(title: $title, stars: $stars, assignedToId: $assignedToId, dueDate: $dueDate, isSubmitting: $isSubmitting, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $QuickAddQuestStateCopyWith<$Res>  {
  factory $QuickAddQuestStateCopyWith(QuickAddQuestState value, $Res Function(QuickAddQuestState) _then) = _$QuickAddQuestStateCopyWithImpl;
@useResult
$Res call({
 String title, int stars, UserId? assignedToId, DateTime? dueDate, bool isSubmitting, String? errorMessage
});




}
/// @nodoc
class _$QuickAddQuestStateCopyWithImpl<$Res>
    implements $QuickAddQuestStateCopyWith<$Res> {
  _$QuickAddQuestStateCopyWithImpl(this._self, this._then);

  final QuickAddQuestState _self;
  final $Res Function(QuickAddQuestState) _then;

/// Create a copy of QuickAddQuestState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? stars = null,Object? assignedToId = freezed,Object? dueDate = freezed,Object? isSubmitting = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,stars: null == stars ? _self.stars : stars // ignore: cast_nullable_to_non_nullable
as int,assignedToId: freezed == assignedToId ? _self.assignedToId : assignedToId // ignore: cast_nullable_to_non_nullable
as UserId?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuickAddQuestState].
extension QuickAddQuestStatePatterns on QuickAddQuestState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuickAddQuestState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuickAddQuestState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuickAddQuestState value)  $default,){
final _that = this;
switch (_that) {
case _QuickAddQuestState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuickAddQuestState value)?  $default,){
final _that = this;
switch (_that) {
case _QuickAddQuestState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  int stars,  UserId? assignedToId,  DateTime? dueDate,  bool isSubmitting,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuickAddQuestState() when $default != null:
return $default(_that.title,_that.stars,_that.assignedToId,_that.dueDate,_that.isSubmitting,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  int stars,  UserId? assignedToId,  DateTime? dueDate,  bool isSubmitting,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _QuickAddQuestState():
return $default(_that.title,_that.stars,_that.assignedToId,_that.dueDate,_that.isSubmitting,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  int stars,  UserId? assignedToId,  DateTime? dueDate,  bool isSubmitting,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _QuickAddQuestState() when $default != null:
return $default(_that.title,_that.stars,_that.assignedToId,_that.dueDate,_that.isSubmitting,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _QuickAddQuestState implements QuickAddQuestState {
  const _QuickAddQuestState({this.title = '', this.stars = 5, this.assignedToId, this.dueDate, this.isSubmitting = false, this.errorMessage});
  

@override@JsonKey() final  String title;
@override@JsonKey() final  int stars;
@override final  UserId? assignedToId;
@override final  DateTime? dueDate;
@override@JsonKey() final  bool isSubmitting;
@override final  String? errorMessage;

/// Create a copy of QuickAddQuestState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuickAddQuestStateCopyWith<_QuickAddQuestState> get copyWith => __$QuickAddQuestStateCopyWithImpl<_QuickAddQuestState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuickAddQuestState&&(identical(other.title, title) || other.title == title)&&(identical(other.stars, stars) || other.stars == stars)&&(identical(other.assignedToId, assignedToId) || other.assignedToId == assignedToId)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,title,stars,assignedToId,dueDate,isSubmitting,errorMessage);

@override
String toString() {
  return 'QuickAddQuestState(title: $title, stars: $stars, assignedToId: $assignedToId, dueDate: $dueDate, isSubmitting: $isSubmitting, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$QuickAddQuestStateCopyWith<$Res> implements $QuickAddQuestStateCopyWith<$Res> {
  factory _$QuickAddQuestStateCopyWith(_QuickAddQuestState value, $Res Function(_QuickAddQuestState) _then) = __$QuickAddQuestStateCopyWithImpl;
@override @useResult
$Res call({
 String title, int stars, UserId? assignedToId, DateTime? dueDate, bool isSubmitting, String? errorMessage
});




}
/// @nodoc
class __$QuickAddQuestStateCopyWithImpl<$Res>
    implements _$QuickAddQuestStateCopyWith<$Res> {
  __$QuickAddQuestStateCopyWithImpl(this._self, this._then);

  final _QuickAddQuestState _self;
  final $Res Function(_QuickAddQuestState) _then;

/// Create a copy of QuickAddQuestState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? stars = null,Object? assignedToId = freezed,Object? dueDate = freezed,Object? isSubmitting = null,Object? errorMessage = freezed,}) {
  return _then(_QuickAddQuestState(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,stars: null == stars ? _self.stars : stars // ignore: cast_nullable_to_non_nullable
as int,assignedToId: freezed == assignedToId ? _self.assignedToId : assignedToId // ignore: cast_nullable_to_non_nullable
as UserId?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on

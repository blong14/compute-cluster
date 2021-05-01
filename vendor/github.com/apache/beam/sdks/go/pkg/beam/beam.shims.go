// Licensed to the Apache Software Foundation (ASF) under one or more
// contributor license agreements.  See the NOTICE file distributed with
// this work for additional information regarding copyright ownership.
// The ASF licenses this file to You under the Apache License, Version 2.0
// (the "License"); you may not use this file except in compliance with
// the License.  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Code generated by starcgen. DO NOT EDIT.
// File: beam.shims.go

package beam

import (
	"context"
	"reflect"

	// Library imports
	"github.com/apache/beam/sdks/go/pkg/beam/core/runtime"
	"github.com/apache/beam/sdks/go/pkg/beam/core/runtime/exec"
	"github.com/apache/beam/sdks/go/pkg/beam/core/typex"
	"github.com/apache/beam/sdks/go/pkg/beam/core/util/reflectx"
)

func init() {
	runtime.RegisterFunction(addFixedKeyFn)
	runtime.RegisterFunction(dropKeyFn)
	runtime.RegisterFunction(dropValueFn)
	runtime.RegisterFunction(explodeFn)
	runtime.RegisterFunction(jsonDec)
	runtime.RegisterFunction(jsonEnc)
	runtime.RegisterFunction(makePartitionFn)
	runtime.RegisterFunction(protoDec)
	runtime.RegisterFunction(protoEnc)
	runtime.RegisterFunction(schemaDec)
	runtime.RegisterFunction(schemaEnc)
	runtime.RegisterFunction(swapKVFn)
	runtime.RegisterType(reflect.TypeOf((*createFn)(nil)).Elem())
	runtime.RegisterType(reflect.TypeOf((*reflect.Type)(nil)).Elem())
	runtime.RegisterType(reflect.TypeOf((*reflectx.Func)(nil)).Elem())
	reflectx.RegisterStructWrapper(reflect.TypeOf((*createFn)(nil)).Elem(), wrapMakerCreateFn)
	reflectx.RegisterFunc(reflect.TypeOf((*func(reflect.Type, []byte) (typex.T, error))(nil)).Elem(), funcMakerReflect۰TypeSliceOfByteГTypex۰TError)
	reflectx.RegisterFunc(reflect.TypeOf((*func(reflect.Type, typex.T) ([]byte, error))(nil)).Elem(), funcMakerReflect۰TypeTypex۰TГSliceOfByteError)
	reflectx.RegisterFunc(reflect.TypeOf((*func([]byte, func(typex.T)) error)(nil)).Elem(), funcMakerSliceOfByteEmitTypex۰TГError)
	reflectx.RegisterFunc(reflect.TypeOf((*func([]typex.T, func(typex.T)))(nil)).Elem(), funcMakerSliceOfTypex۰TEmitTypex۰TГ)
	reflectx.RegisterFunc(reflect.TypeOf((*func(string, reflect.Type, []byte) reflectx.Func)(nil)).Elem(), funcMakerStringReflect۰TypeSliceOfByteГReflectx۰Func)
	reflectx.RegisterFunc(reflect.TypeOf((*func(typex.T) (int, typex.T))(nil)).Elem(), funcMakerTypex۰TГIntTypex۰T)
	reflectx.RegisterFunc(reflect.TypeOf((*func(typex.T) ([]byte, error))(nil)).Elem(), funcMakerTypex۰TГSliceOfByteError)
	reflectx.RegisterFunc(reflect.TypeOf((*func(typex.X, typex.Y) typex.X)(nil)).Elem(), funcMakerTypex۰XTypex۰YГTypex۰X)
	reflectx.RegisterFunc(reflect.TypeOf((*func(typex.X, typex.Y) typex.Y)(nil)).Elem(), funcMakerTypex۰XTypex۰YГTypex۰Y)
	reflectx.RegisterFunc(reflect.TypeOf((*func(typex.X, typex.Y) (typex.Y, typex.X))(nil)).Elem(), funcMakerTypex۰XTypex۰YГTypex۰YTypex۰X)
	exec.RegisterEmitter(reflect.TypeOf((*func(typex.T))(nil)).Elem(), emitMakerTypex۰T)
}

func wrapMakerCreateFn(fn interface{}) map[string]reflectx.Func {
	dfn := fn.(*createFn)
	return map[string]reflectx.Func{
		"ProcessElement": reflectx.MakeFunc(func(a0 []byte, a1 func(typex.T)) error { return dfn.ProcessElement(a0, a1) }),
	}
}

type callerReflect۰TypeSliceOfByteГTypex۰TError struct {
	fn func(reflect.Type, []byte) (typex.T, error)
}

func funcMakerReflect۰TypeSliceOfByteГTypex۰TError(fn interface{}) reflectx.Func {
	f := fn.(func(reflect.Type, []byte) (typex.T, error))
	return &callerReflect۰TypeSliceOfByteГTypex۰TError{fn: f}
}

func (c *callerReflect۰TypeSliceOfByteГTypex۰TError) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerReflect۰TypeSliceOfByteГTypex۰TError) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerReflect۰TypeSliceOfByteГTypex۰TError) Call(args []interface{}) []interface{} {
	out0, out1 := c.fn(args[0].(reflect.Type), args[1].([]byte))
	return []interface{}{out0, out1}
}

func (c *callerReflect۰TypeSliceOfByteГTypex۰TError) Call2x2(arg0, arg1 interface{}) (interface{}, interface{}) {
	return c.fn(arg0.(reflect.Type), arg1.([]byte))
}

type callerReflect۰TypeTypex۰TГSliceOfByteError struct {
	fn func(reflect.Type, typex.T) ([]byte, error)
}

func funcMakerReflect۰TypeTypex۰TГSliceOfByteError(fn interface{}) reflectx.Func {
	f := fn.(func(reflect.Type, typex.T) ([]byte, error))
	return &callerReflect۰TypeTypex۰TГSliceOfByteError{fn: f}
}

func (c *callerReflect۰TypeTypex۰TГSliceOfByteError) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerReflect۰TypeTypex۰TГSliceOfByteError) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerReflect۰TypeTypex۰TГSliceOfByteError) Call(args []interface{}) []interface{} {
	out0, out1 := c.fn(args[0].(reflect.Type), args[1].(typex.T))
	return []interface{}{out0, out1}
}

func (c *callerReflect۰TypeTypex۰TГSliceOfByteError) Call2x2(arg0, arg1 interface{}) (interface{}, interface{}) {
	return c.fn(arg0.(reflect.Type), arg1.(typex.T))
}

type callerSliceOfByteEmitTypex۰TГError struct {
	fn func([]byte, func(typex.T)) error
}

func funcMakerSliceOfByteEmitTypex۰TГError(fn interface{}) reflectx.Func {
	f := fn.(func([]byte, func(typex.T)) error)
	return &callerSliceOfByteEmitTypex۰TГError{fn: f}
}

func (c *callerSliceOfByteEmitTypex۰TГError) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerSliceOfByteEmitTypex۰TГError) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerSliceOfByteEmitTypex۰TГError) Call(args []interface{}) []interface{} {
	out0 := c.fn(args[0].([]byte), args[1].(func(typex.T)))
	return []interface{}{out0}
}

func (c *callerSliceOfByteEmitTypex۰TГError) Call2x1(arg0, arg1 interface{}) interface{} {
	return c.fn(arg0.([]byte), arg1.(func(typex.T)))
}

type callerSliceOfTypex۰TEmitTypex۰TГ struct {
	fn func([]typex.T, func(typex.T))
}

func funcMakerSliceOfTypex۰TEmitTypex۰TГ(fn interface{}) reflectx.Func {
	f := fn.(func([]typex.T, func(typex.T)))
	return &callerSliceOfTypex۰TEmitTypex۰TГ{fn: f}
}

func (c *callerSliceOfTypex۰TEmitTypex۰TГ) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerSliceOfTypex۰TEmitTypex۰TГ) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerSliceOfTypex۰TEmitTypex۰TГ) Call(args []interface{}) []interface{} {
	c.fn(args[0].([]typex.T), args[1].(func(typex.T)))
	return []interface{}{}
}

func (c *callerSliceOfTypex۰TEmitTypex۰TГ) Call2x0(arg0, arg1 interface{}) {
	c.fn(arg0.([]typex.T), arg1.(func(typex.T)))
}

type callerStringReflect۰TypeSliceOfByteГReflectx۰Func struct {
	fn func(string, reflect.Type, []byte) reflectx.Func
}

func funcMakerStringReflect۰TypeSliceOfByteГReflectx۰Func(fn interface{}) reflectx.Func {
	f := fn.(func(string, reflect.Type, []byte) reflectx.Func)
	return &callerStringReflect۰TypeSliceOfByteГReflectx۰Func{fn: f}
}

func (c *callerStringReflect۰TypeSliceOfByteГReflectx۰Func) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerStringReflect۰TypeSliceOfByteГReflectx۰Func) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerStringReflect۰TypeSliceOfByteГReflectx۰Func) Call(args []interface{}) []interface{} {
	out0 := c.fn(args[0].(string), args[1].(reflect.Type), args[2].([]byte))
	return []interface{}{out0}
}

func (c *callerStringReflect۰TypeSliceOfByteГReflectx۰Func) Call3x1(arg0, arg1, arg2 interface{}) interface{} {
	return c.fn(arg0.(string), arg1.(reflect.Type), arg2.([]byte))
}

type callerTypex۰TГIntTypex۰T struct {
	fn func(typex.T) (int, typex.T)
}

func funcMakerTypex۰TГIntTypex۰T(fn interface{}) reflectx.Func {
	f := fn.(func(typex.T) (int, typex.T))
	return &callerTypex۰TГIntTypex۰T{fn: f}
}

func (c *callerTypex۰TГIntTypex۰T) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerTypex۰TГIntTypex۰T) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerTypex۰TГIntTypex۰T) Call(args []interface{}) []interface{} {
	out0, out1 := c.fn(args[0].(typex.T))
	return []interface{}{out0, out1}
}

func (c *callerTypex۰TГIntTypex۰T) Call1x2(arg0 interface{}) (interface{}, interface{}) {
	return c.fn(arg0.(typex.T))
}

type callerTypex۰TГSliceOfByteError struct {
	fn func(typex.T) ([]byte, error)
}

func funcMakerTypex۰TГSliceOfByteError(fn interface{}) reflectx.Func {
	f := fn.(func(typex.T) ([]byte, error))
	return &callerTypex۰TГSliceOfByteError{fn: f}
}

func (c *callerTypex۰TГSliceOfByteError) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerTypex۰TГSliceOfByteError) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerTypex۰TГSliceOfByteError) Call(args []interface{}) []interface{} {
	out0, out1 := c.fn(args[0].(typex.T))
	return []interface{}{out0, out1}
}

func (c *callerTypex۰TГSliceOfByteError) Call1x2(arg0 interface{}) (interface{}, interface{}) {
	return c.fn(arg0.(typex.T))
}

type callerTypex۰XTypex۰YГTypex۰X struct {
	fn func(typex.X, typex.Y) typex.X
}

func funcMakerTypex۰XTypex۰YГTypex۰X(fn interface{}) reflectx.Func {
	f := fn.(func(typex.X, typex.Y) typex.X)
	return &callerTypex۰XTypex۰YГTypex۰X{fn: f}
}

func (c *callerTypex۰XTypex۰YГTypex۰X) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerTypex۰XTypex۰YГTypex۰X) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerTypex۰XTypex۰YГTypex۰X) Call(args []interface{}) []interface{} {
	out0 := c.fn(args[0].(typex.X), args[1].(typex.Y))
	return []interface{}{out0}
}

func (c *callerTypex۰XTypex۰YГTypex۰X) Call2x1(arg0, arg1 interface{}) interface{} {
	return c.fn(arg0.(typex.X), arg1.(typex.Y))
}

type callerTypex۰XTypex۰YГTypex۰Y struct {
	fn func(typex.X, typex.Y) typex.Y
}

func funcMakerTypex۰XTypex۰YГTypex۰Y(fn interface{}) reflectx.Func {
	f := fn.(func(typex.X, typex.Y) typex.Y)
	return &callerTypex۰XTypex۰YГTypex۰Y{fn: f}
}

func (c *callerTypex۰XTypex۰YГTypex۰Y) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerTypex۰XTypex۰YГTypex۰Y) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerTypex۰XTypex۰YГTypex۰Y) Call(args []interface{}) []interface{} {
	out0 := c.fn(args[0].(typex.X), args[1].(typex.Y))
	return []interface{}{out0}
}

func (c *callerTypex۰XTypex۰YГTypex۰Y) Call2x1(arg0, arg1 interface{}) interface{} {
	return c.fn(arg0.(typex.X), arg1.(typex.Y))
}

type callerTypex۰XTypex۰YГTypex۰YTypex۰X struct {
	fn func(typex.X, typex.Y) (typex.Y, typex.X)
}

func funcMakerTypex۰XTypex۰YГTypex۰YTypex۰X(fn interface{}) reflectx.Func {
	f := fn.(func(typex.X, typex.Y) (typex.Y, typex.X))
	return &callerTypex۰XTypex۰YГTypex۰YTypex۰X{fn: f}
}

func (c *callerTypex۰XTypex۰YГTypex۰YTypex۰X) Name() string {
	return reflectx.FunctionName(c.fn)
}

func (c *callerTypex۰XTypex۰YГTypex۰YTypex۰X) Type() reflect.Type {
	return reflect.TypeOf(c.fn)
}

func (c *callerTypex۰XTypex۰YГTypex۰YTypex۰X) Call(args []interface{}) []interface{} {
	out0, out1 := c.fn(args[0].(typex.X), args[1].(typex.Y))
	return []interface{}{out0, out1}
}

func (c *callerTypex۰XTypex۰YГTypex۰YTypex۰X) Call2x2(arg0, arg1 interface{}) (interface{}, interface{}) {
	return c.fn(arg0.(typex.X), arg1.(typex.Y))
}

type emitNative struct {
	n  exec.ElementProcessor
	fn interface{}

	ctx   context.Context
	ws    []typex.Window
	et    typex.EventTime
	value exec.FullValue
}

func (e *emitNative) Init(ctx context.Context, ws []typex.Window, et typex.EventTime) error {
	e.ctx = ctx
	e.ws = ws
	e.et = et
	return nil
}

func (e *emitNative) Value() interface{} {
	return e.fn
}

func emitMakerTypex۰T(n exec.ElementProcessor) exec.ReusableEmitter {
	ret := &emitNative{n: n}
	ret.fn = ret.invokeTypex۰T
	return ret
}

func (e *emitNative) invokeTypex۰T(val typex.T) {
	e.value = exec.FullValue{Windows: e.ws, Timestamp: e.et, Elm: val}
	if err := e.n.ProcessElement(e.ctx, &e.value); err != nil {
		panic(err)
	}
}

// DO NOT MODIFY: GENERATED CODE

--[[
https://github.com/bysreg/gideros-OLib

Copyright (C) 2013 Hilman Beyri(hilmanbeyri@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction, 
including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do 
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
--]]

--berisi fungsi-fungsi yang mempermudah hidup
OHelper = Core.class()

--mengembalikan semua kombinasi dari nCk
function OHelper.generate_combination(n, k)		
	local ret = {}	
	local iter = {}
	local m = k		
	
	for i=1,k do
		table.insert(iter, i)		
	end
	
	while(iter[1] <= n-k + 1) do		
		local comb = {}
		for i=1, #iter do comb[i] = iter[i] end
		table.insert(ret, comb)		
		
		m = k
		iter[m] = iter[m] + 1
		while(m>1 and iter[m] > n-k+m) do
			iter[m-1] = iter[m-1] + 1
			m = m - 1
		end
		
		for i=m+1,k do
			iter[i] = iter[i-1] + 1
		end		
	end	
	
	return ret
end

--fungsi ini akan mengedit in-place variabel t dan mereverse elemen-elemennya, dianggap elemen ada berurutan 
--dari 1 .. #t (tidak bolong-bolong)
function OHelper.reverse_table_inplace(t)
	local size = #t
	for i=1, math.floor(size/2) do
		local temp = t[i]
		t[i] = t[size - i + 1]
		t[size - i + 1] = temp
	end

	return t
end

--fungsinya hampir mirip dengan fugnsi unpack bawaan dari lua, hanya saja memastikan bahwa jika argumen terakhirnya nil, unpack tidak
--memberikan hasil yang salah
function OHelper.unpack(t)	
	return unpack(t, 1, table.maxn(t))
end
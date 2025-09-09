
<a name="suilend_cell"></a>

# Module `suilend::cell`



-  [Struct `Cell`](#suilend_cell_Cell)
-  [Function `new`](#suilend_cell_new)
-  [Function `set`](#suilend_cell_set)
-  [Function `get`](#suilend_cell_get)
-  [Function `destroy`](#suilend_cell_destroy)


<pre><code><b>use</b> <a href="../dependencies/std/option.md#std_option">std::option</a>;
<b>use</b> <a href="../dependencies/std/vector.md#std_vector">std::vector</a>;
</code></pre>



<a name="suilend_cell_Cell"></a>

## Struct `Cell`



<pre><code><b>public</b> <b>struct</b> <a href="../suilend/cell.md#suilend_cell_Cell">Cell</a>&lt;Element&gt; <b>has</b> store
</code></pre>



<details>
<summary>Fields</summary>


<dl>
<dt>
<code>element: <a href="../dependencies/std/option.md#std_option_Option">std::option::Option</a>&lt;Element&gt;</code>
</dt>
<dd>
</dd>
</dl>


</details>

<a name="suilend_cell_new"></a>

## Function `new`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/cell.md#suilend_cell_new">new</a>&lt;Element&gt;(element: Element): <a href="../suilend/cell.md#suilend_cell_Cell">suilend::cell::Cell</a>&lt;Element&gt;
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/cell.md#suilend_cell_new">new</a>&lt;Element&gt;(element: Element): <a href="../suilend/cell.md#suilend_cell_Cell">Cell</a>&lt;Element&gt; {
    <a href="../suilend/cell.md#suilend_cell_Cell">Cell</a> { element: option::some(element) }
}
</code></pre>



</details>

<a name="suilend_cell_set"></a>

## Function `set`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/cell.md#suilend_cell_set">set</a>&lt;Element&gt;(<a href="../suilend/cell.md#suilend_cell">cell</a>: &<b>mut</b> <a href="../suilend/cell.md#suilend_cell_Cell">suilend::cell::Cell</a>&lt;Element&gt;, element: Element): Element
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/cell.md#suilend_cell_set">set</a>&lt;Element&gt;(<a href="../suilend/cell.md#suilend_cell">cell</a>: &<b>mut</b> <a href="../suilend/cell.md#suilend_cell_Cell">Cell</a>&lt;Element&gt;, element: Element): Element {
    option::swap(&<b>mut</b> <a href="../suilend/cell.md#suilend_cell">cell</a>.element, element)
}
</code></pre>



</details>

<a name="suilend_cell_get"></a>

## Function `get`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/cell.md#suilend_cell_get">get</a>&lt;Element&gt;(<a href="../suilend/cell.md#suilend_cell">cell</a>: &<a href="../suilend/cell.md#suilend_cell_Cell">suilend::cell::Cell</a>&lt;Element&gt;): &Element
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/cell.md#suilend_cell_get">get</a>&lt;Element&gt;(<a href="../suilend/cell.md#suilend_cell">cell</a>: &<a href="../suilend/cell.md#suilend_cell_Cell">Cell</a>&lt;Element&gt;): &Element {
    option::borrow(&<a href="../suilend/cell.md#suilend_cell">cell</a>.element)
}
</code></pre>



</details>

<a name="suilend_cell_destroy"></a>

## Function `destroy`



<pre><code><b>public</b> <b>fun</b> <a href="../suilend/cell.md#suilend_cell_destroy">destroy</a>&lt;Element&gt;(<a href="../suilend/cell.md#suilend_cell">cell</a>: <a href="../suilend/cell.md#suilend_cell_Cell">suilend::cell::Cell</a>&lt;Element&gt;): Element
</code></pre>



<details>
<summary>Implementation</summary>


<pre><code><b>public</b> <b>fun</b> <a href="../suilend/cell.md#suilend_cell_destroy">destroy</a>&lt;Element&gt;(<a href="../suilend/cell.md#suilend_cell">cell</a>: <a href="../suilend/cell.md#suilend_cell_Cell">Cell</a>&lt;Element&gt;): Element {
    <b>let</b> <a href="../suilend/cell.md#suilend_cell_Cell">Cell</a> { element } = <a href="../suilend/cell.md#suilend_cell">cell</a>;
    option::destroy_some(element)
}
</code></pre>



</details>

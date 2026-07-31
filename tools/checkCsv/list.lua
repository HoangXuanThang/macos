
-- 公式检测
formula = {
	{csvName = "card_ability", colName = "attrNum1"},
	{csvName = "skill", colName = "damageFormula"},
	{csvName = "skill", colName = "hpFormula"},
	{csvName = "skill_process", colName = "buffProb"},
	{csvName = "skill_process", colName = "buffValue1"},
	{csvName = "skill_process", colName = "buffLifeRound"},
	{csvName = "skill_process", colName = "skillTarget"},
	{csvName = "buff", colName = "triggerBehaviors"},
}


-- 描述公式检测
formulaDesc = {
	{csvName = "skill", colName = "describe"},
}

-- check res .skel .mp3 .mp4 .png
resPaths = {
	{csvName = "card_ability", colName = "icon"},
	{csvName = "unit", colName = "icon"},
	{csvName = "unit", colName = "cardIcon"},
	{csvName = "unit", colName = "unitRes"},
	-- {csvName = "unit", colName = "show"},
	{csvName = "unit", colName = "cardShow"},
	-- {csvName = "skill", colName = "iconRes"},
	-- {csvName = "skill", colName = "effectBigName"},
	{csvName = "skill_process", colName = "effectRes"},
	{csvName = "buff", colName = "effectRes"},
	{csvName = "buff", colName = "textResPath"},
	{csvName = "buff", colName = "iconResPath"},
	{csvName = "skill", colName = "sound", colName2 = "res"},
}

awardPaths = {
	{csvName = "yunying.collectcard", colName = "award"},
	{csvName = "yunying.dailybuy", colName = "item"},
	{csvName = "yunying.fightpointaward", colName = "award"},
	{csvName = "yunying.fightrankaward", colName = "award"},
	{csvName = "yunying.gateaward", colName = "award"},
	{csvName = "yunying.generaltask", colName = "award"},
	{csvName = "yunying.itembuy", colName = "item"},
	{csvName = "yunying.itemexchange", colName = "items"},
	{csvName = "yunying.levelaward", colName = "award"},
	{csvName = "yunying.limitboxpointaward", colName = "award"},
	{csvName = "yunying.limitboxrankaward", colName = "award"},
	{csvName = "yunying.loginweal", colName = "award"},
	{csvName = "yunying.passport_award", colName = "normalAward"},
	{csvName = "yunying.passport_award", colName = "eliteAward"},
}

checkMethod = {
	{"formula", "check formula", "检查公式格式问题"},
	{"award", "check award", "检查奖励类dict字典配置是否合理"},
	{"cross", "check cross", "检查cross配置表是否正常"},
	{"res", "check not exist res", "检查资源是否存在"},
	{"skill", "check csv.skill not exist Id", "检查技能过程是否存在"},
	{"skill_process", "check csv.skill_process not used Id", "检查技能过程是否使用"},
	{"buff", "check csv.buff not used Id", "检查buff是否使用"},
	{"scene", "check sceneCount and monsters id", "检查场景配置是否存在"},
	{"draw_lib", "check draw_items_lib item id", "检查抽取配置 item id 是否存在"},
}

-- title, summaryInfo, testAllCount, infoCount, warnCount, errorCount, results
htmlTextTemplate = [[<!DOCTYPE html>
<html>
  <head>
	<meta charset="utf-8"/>
	<title>Test Report</title>
	<!-- <link href="assets/style.css" rel="stylesheet" type="text/css"/> -->
	<style type="text/css"/>
body {
	font-family: Helvetica, Arial, sans-serif;
	font-size: 12px;
	/* do not increase min-width as some may use split screens */
	min-width: 800px;
	color: #999;
}

h1 {
	font-size: 24px;
	color: black;
}

h2 {
	font-size: 16px;
	color: black;
}

p {
    color: black;
}

a {
	color: #999;
}

table {
	border-collapse: collapse;
}

/******************************
 * SUMMARY INFORMATION
 ******************************/

#environment td {
	padding: 5px;
	border: 1px solid #E6E6E6;
}

#environment tr:nth-child(odd) {
	background-color: #f6f6f6;
}

/******************************
 * TEST RESULT COLORS
 ******************************/
span.passed, .passed .col-result, span.info, .info .col-result  {
	color: green;
}
span.warn, span.xfailed, span.rerun, .warn .col-result, .xfailed .col-result, .rerun .col-result {
	color: orange;
}
span.error, span.failed, span.xpassed, .error .col-result, .failed .col-result, .xpassed .col-result  {
	color: red;
}


/******************************
 * RESULTS TABLE
 *
 * 1. Table Layout
 * 2. Extra
 * 3. Sorting items
 *
 ******************************/

/*------------------
 * 1. Table Layout
 *------------------*/

#results-table {
	border: 1px solid #e6e6e6;
	color: #999;
	font-size: 12px;
	width: 100%%
}

#results-table th, #results-table td {
	padding: 5px;
	border: 1px solid #E6E6E6;
	text-align: left
}
#results-table th {
	font-weight: bold
}

/*------------------
 * 2. Extra
 *------------------*/

.log:only-child {
	height: inherit
}
.log {
	background-color: #e6e6e6;
	border: 1px solid #e6e6e6;
	color: black;
	display: block;
	font-family: "Courier New", Courier, monospace;
	height: 230px;
	overflow-y: scroll;
	padding: 5px;
	white-space: pre-wrap
}
div.image {
	border: 1px solid #e6e6e6;
	float: right;
	height: 240px;
	margin-left: 5px;
	overflow: hidden;
	width: 320px
}
div.image img {
	width: 320px
}
.collapsed {
	display: none;
}
.expander::after {
	content: " (show details)";
	color: #BBB;
	font-style: italic;
	cursor: pointer;
}
.collapser::after {
	content: " (hide details)";
	color: #BBB;
	font-style: italic;
	cursor: pointer;
}

/*------------------
 * 3. Sorting items
 *------------------*/
.sortable {
	cursor: pointer;
}

.sort-icon {
	font-size: 0px;
	float: left;
	margin-right: 5px;
	margin-top: 5px;
	/*triangle*/
	width: 0;
	height: 0;
	border-left: 8px solid transparent;
	border-right: 8px solid transparent;
}

.inactive .sort-icon {
	/*finish triangle*/
	border-top: 8px solid #E6E6E6;
}

.asc.active .sort-icon {
	/*finish triangle*/
	border-bottom: 8px solid #999;
}

.desc.active .sort-icon {
	/*finish triangle*/
	border-top: 8px solid #999;
}

	</style>
</head>
  <body onLoad="init()">
	<script>/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */


function toArray(iter) {
	if (iter === null) {
		return null;
	}
	return Array.prototype.slice.call(iter);
}

function find(selector, elem) {
	if (!elem) {
		elem = document;
	}
	return elem.querySelector(selector);
}

function find_all(selector, elem) {
	if (!elem) {
		elem = document;
	}
	return toArray(elem.querySelectorAll(selector));
}

function sort_column(elem) {
	toggle_sort_states(elem);
	var colIndex = toArray(elem.parentNode.childNodes).indexOf(elem);
	var key;
	if (elem.classList.contains('numeric')) {
		key = key_num;
	} else if (elem.classList.contains('result')) {
		key = key_result;
	} else {
		key = key_alpha;
	}
	sort_table(elem, key(colIndex));
}

function show_all_extras() {
	find_all('.col-result').forEach(show_extras);
}

function hide_all_extras() {
	find_all('.col-result').forEach(hide_extras);
}

function show_extras(colresult_elem) {
	var extras = colresult_elem.parentNode.nextElementSibling;
	var expandcollapse = colresult_elem.firstElementChild;
	extras.classList.remove("collapsed");
	expandcollapse.classList.remove("expander");
	expandcollapse.classList.add("collapser");
}

function hide_extras(colresult_elem) {
	var extras = colresult_elem.parentNode.nextElementSibling;
	var expandcollapse = colresult_elem.firstElementChild;
	extras.classList.add("collapsed");
	expandcollapse.classList.remove("collapser");
	expandcollapse.classList.add("expander");
}

function show_filters() {
	var filter_items = document.getElementsByClassName('filter');
	for (var i = 0; i < filter_items.length; i++)
		filter_items[i].hidden = false;
}

function add_collapse() {
	// Add links for show/hide all
	var resulttable = find('table#results-table');
	var showhideall = document.createElement("p");
	showhideall.innerHTML = '<a href="javascript:show_all_extras()">Show all details</a> / ' +
							'<a href="javascript:hide_all_extras()">Hide all details</a>';
	resulttable.parentElement.insertBefore(showhideall, resulttable);

	// Add show/hide link to each result
	find_all('.col-result').forEach(function(elem) {
		var collapsed = get_query_parameter('collapsed') || 'Passed';
		var extras = elem.parentNode.nextElementSibling;
		var expandcollapse = document.createElement("span");
		if (collapsed.includes(elem.innerHTML)) {
			extras.classList.add("collapsed");
			expandcollapse.classList.add("expander");
		} else {
			expandcollapse.classList.add("collapser");
		}
		elem.appendChild(expandcollapse);

		elem.addEventListener("click", function(event) {
			if (event.currentTarget.parentNode.nextElementSibling.classList.contains("collapsed")) {
				show_extras(event.currentTarget);
			} else {
				hide_extras(event.currentTarget);
			}
		});
	})
}

function get_query_parameter(name) {
	var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
	return match && decodeURIComponent(match[1].replace(/\+/g, ' '));
}

function init () {
	reset_sort_headers();

	add_collapse();

	show_filters();

	sort_column(find('.initial-sort'));

	find_all('.sortable').forEach(function(elem) {
		elem.addEventListener("click",
							  function(event) {
								  sort_column(elem);
							  }, false)
	});

};

function sort_table(clicked, key_func) {
	var rows = find_all('.results-table-row');
	var reversed = !clicked.classList.contains('asc');
	var sorted_rows = sort(rows, key_func, reversed);
	/* Whole table is removed here because browsers acts much slower
	 * when appending existing elements.
	 */
	var thead = document.getElementById("results-table-head");
	document.getElementById('results-table').remove();
	var parent = document.createElement("table");
	parent.id = "results-table";
	parent.appendChild(thead);
	sorted_rows.forEach(function(elem) {
		parent.appendChild(elem);
	});
	document.getElementsByTagName("BODY")[0].appendChild(parent);
}

function sort(items, key_func, reversed) {
	var sort_array = items.map(function(item, i) {
		return [key_func(item), i];
	});

	sort_array.sort(function(a, b) {
		var key_a = a[0];
		var key_b = b[0];

		if (key_a == key_b) return 0;

		if (reversed) {
			return (key_a < key_b ? 1 : -1);
		} else {
			return (key_a > key_b ? 1 : -1);
		}
	});

	return sort_array.map(function(item) {
		var index = item[1];
		return items[index];
	});
}

function key_alpha(col_index) {
	return function(elem) {
		return elem.childNodes[1].childNodes[col_index].firstChild.data.toLowerCase();
	};
}

function key_num(col_index) {
	return function(elem) {
		return parseFloat(elem.childNodes[1].childNodes[col_index].firstChild.data);
	};
}

function key_result(col_index) {
	return function(elem) {
		var strings = ['Error', 'Failed', 'Rerun', 'XFailed', 'XPassed',
					   'Skipped', 'Passed'];
		return strings.indexOf(elem.childNodes[1].childNodes[col_index].firstChild.data);
	};
}

function reset_sort_headers() {
	find_all('.sort-icon').forEach(function(elem) {
		elem.parentNode.removeChild(elem);
	});
	find_all('.sortable').forEach(function(elem) {
		var icon = document.createElement("div");
		icon.className = "sort-icon";
		icon.textContent = "vvv";
		elem.insertBefore(icon, elem.firstChild);
		elem.classList.remove("desc", "active");
		elem.classList.add("asc", "inactive");
	});
}

function toggle_sort_states(elem) {
	//if active, toggle between asc and desc
	if (elem.classList.contains('active')) {
		elem.classList.toggle('asc');
		elem.classList.toggle('desc');
	}

	//if inactive, reset all other functions and add ascending active
	if (elem.classList.contains('inactive')) {
		reset_sort_headers();
		elem.classList.remove('inactive');
		elem.classList.add('active');
	}
}

function is_all_rows_hidden(value) {
  return value.hidden == false;
}

function filter_table(elem) {
	var outcome_att = "data-test-result";
	var outcome = elem.getAttribute(outcome_att);
	class_outcome = outcome + " results-table-row";
	var outcome_rows = document.getElementsByClassName(class_outcome);

	for(var i = 0; i < outcome_rows.length; i++){
		outcome_rows[i].hidden = !elem.checked;
	}

	var rows = find_all('.results-table-row').filter(is_all_rows_hidden);
	var all_rows_hidden = rows.length == 0 ? true : false;
	var not_found_message = document.getElementById("not-found-message");
	not_found_message.hidden = !all_rows_hidden;
}
</script>
	<h1>%s</h1>
	<p>Report generated on %s by <a href="https://pypi.python.org/pypi/pytest-html">pytest-html</a> v1.22.1</p>
	<h2>Environment</h2>
	<table id="environment">

	  	<tr>
			<td>Python</td>
			<td>2.7.15</td></tr>
	</table>
	<h2>Summary</h2>
	<p>%s</p>
	<p class="filter" hidden="true">(Un)check the boxes to filter the results.</p>
	<input checked="true" class="filter" data-test-result="info" hidden="true" name="filter_checkbox" onChange="filter_table(this)" type="checkbox"/>
		<span class="info"><font color="#00CC99">%s info</font></span>,
	<input checked="true" class="filter" data-test-result="warn" hidden="true" name="filter_checkbox" onChange="filter_table(this)" type="checkbox"/>
		<span class="warn"><font color="#FF9900">%s warn</font></span>,
	<input checked="true" class="filter" data-test-result="error" hidden="true" name="filter_checkbox" onChange="filter_table(this)" type="checkbox"/>
		<span class="error"><font color="#FF0000">%s error</font></span>
	<h2>Results</h2>
	<table id="results-table">
	  <thead id="results-table-head">
		<tr>
			<th class="sortable" col="result">Result</th>
			<th class="sortable result initial-sort" col="method">Method</th>
			<th class="sortable" col="desc">Desc</th>
		</tr>
		<tr hidden="true" id="not-found-message">
			<th colspan="3">No results found. Try to check the filters</th></tr>
%s
	</table>
</body></html>
]]

-- key, result(upper key), method, desc, log
htmlTextResultTemplate = [[
	<tbody class="%s results-table-row">
		<tr>
			<td class="col-result">%s</td>
			<td class="col-method">%s</td>
			<td class="col-desc">%s</td>
		</tr>
		<tr>
			<td class="extra" colspan="3">
				<div class="log">%s
				</div>
			</td>
		</tr>
	</tbody>
]]

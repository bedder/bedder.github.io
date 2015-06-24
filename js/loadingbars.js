$(".javascript_warning").remove();

$(".loading_bars").each(function() {
	var tag = $(this);
	$.getJSON($(this).attr("src"), function(data) {
		$.each(data, function(key, val) {
			tag.append("<div class=\"loading_bar\" title=\"" + val.description + "\"><div class=\"loading_bar_length\" style=\"width:" + val.percent + "%;\"><div class=\"loading_bar_inner wow\" style=\"background-color: hsl(" + val.percent + ", 40%, 60%);\"></div></div><div class=\"loading_bar_text\">" + val.name + "</div></div>");
		});
	});
});
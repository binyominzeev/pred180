var selected_parameters_row=0;
var selected_records_row=0;
var neighborCount=0;

$(document).ready( function() {
	$('#parameters tbody tr.clickable').click(function () {
		
		$(this).css('background-color','#eee');
		$("#parameters tbody tr.clickable[value='"+selected_parameters_row+"']").css('background-color','#fff');
		
		selected_parameters_row = $(this).attr("value");
		
		$.get("records.pl", { row: $(this).attr("value") })
			.done(function(data) {
				$("#records").html(data);
				$('#records_table').tablesorter();
				$('#records_table').tableScroll({height:200});
				
				$('#records tbody tr').click(function () {
					$("#show").html(
						"<img src=\"image_neighbors.pl?showneighbors=" + neighborCount + "&word=" + $(this).attr("value") + "&dataset=" + dataset + "\" />" + 
						"<img src=\"image.pl?showall=1&word=" + $(this).attr("value") + "&dataset=" + dataset + "\" />"
					);
				})
				.click(function () {
					$(this).css('background-color','#eee');
					
					$("#records tbody tr.clickable[value='"+selected_records_row+"']").css('background-color','#fff');
					selected_records_row = $(this).attr("value");
				})
				.hover(function () {
					if ($(this).attr("value") != selected_records_row) {
					  $(this).css('background-color','#D8F6CE');
				  }
				   }, function () {
					  if ($(this).attr("value") != selected_records_row) {
						$(this).css('background-color','#fff');
					}
				});
			});
	})
	
	.hover(function () {
		  if ($(this).attr("value") != selected_parameters_row) {
			$(this).css('background-color','#D8F6CE');
		}
	   }, function () {
		  if ($(this).attr("value") != selected_parameters_row) {
			$(this).css('background-color','#fff');
		}
	});
	
	$('#parameters_table').tablesorter();
	$('#parameters_table').tableScroll({height:200});
	$('#records_table').tableScroll({height:200});
	
	$("input").keypress(function(event) {
		if (event.which == 13) {
			event.preventDefault();
			$("form").submit();
		}
	});
});

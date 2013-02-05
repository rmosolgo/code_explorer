
$('#nav_explore').addClass('active')

j=1
w = $('#chart').width()
h = $('#chart').width()
r = d3.max([w / 2, h /2 ])
x = d3.scale.linear().range([0, 2 * Math.PI])
y = d3.scale.sqrt().domain([0, .3,  1]).range([1, r/2,  r])
section_stroke_width = 1
p = 5 #  padding
duration = 500
  #  Stores position for both zoom and click
Position = 
  translate: [0,0]
  scale: 1

start_index_100 = 1
start_index_200 = 298
start_index_300 = 428
start_index_400 = 635
start_index_500 = 697
start_index_600 = 722
start_index_700 = 735
start_index_900 = 767
end_index = 789

vis_red = '#d11'
vis_orange = '#d71'
vis_yellow = '#dd1'
vis_yellow_green = '#8d1'
vis_green= 'green'
vis_blue= '#47e'
vis_indigo = 'indigo'


revColor = (c) ->
  # This could probably be abstracted a bit better...
  c = Number(c)
  if c == 0 then "#ddd"
  else if start_index_200 > c >= start_index_100  
    d3.scale.linear().range([vis_red, vis_orange]).domain([start_index_100,start_index_200-1])(c) 
  else if start_index_300 > c >= start_index_200 
    d3.scale.linear().range([ vis_orange, vis_red, vis_orange]).domain([start_index_200, start_index_200+1, start_index_300-1]) c
  else if start_index_400 > c >= start_index_300
    d3.scale.linear().range([vis_yellow,vis_yellow_green,vis_yellow]).domain([start_index_300, start_index_300+1, start_index_400-1]) c  
  else if start_index_500 > c >= start_index_400
    d3.scale.linear().range([vis_green,vis_yellow_green]).domain([start_index_400, start_index_500]) c 
  else if start_index_600 > c >= start_index_500  
    d3.scale.linear().range([vis_blue, '#253cb7',vis_blue]).domain([start_index_500, start_index_500+1, start_index_600-1]) c
  else if start_index_700 > c >= start_index_600  
    d3.scale.linear().range(['darkblue','#253cb7']).domain([start_index_600, start_index_700]) c
  else if start_index_900 > c >= start_index_700  
    d3.scale.linear().range(['indigo','violet']).domain([start_index_700, start_index_900]) c
  else if end_index > c >= start_index_900
    d3.scale.linear().range(['#eee','#777','#eee']).domain([start_index_900, start_index_900+1, end_index-1]) c
  else
      console.log(c) 
      "#a23"

zoomAction = () ->
  t++
  Position.translate = d3.event.translate
  Position.scale = d3.event.scale
  console.log("zoom", t, Position.translate, Position.scale,  "event.t:", d3.event.translate, "event.s:", d3.event.scale)
  items.attr('stroke-width', d3.min([section_stroke_width, (section_stroke_width/Position.scale)])+"px" )
  #d3.selectAll('.code-text').style("font-size", (d,i) -> $(this).css('font-size'))
  outer_vis.attr("transform", "translate(#{Position.translate}) scale(#{Position.scale})")

zoom = d3.behavior.zoom().translate(Position.translate).scale(Position.scale).on("zoom", zoomAction)
t = 0

svg = d3.select("#chart")
    .append("svg")
        .attr("width", w + p * 2)
        .attr("height", h + p * 2)
        .style("border", "2px solid #ccc")

outer_vis = svg.append("g")
      .call(zoom)
      .append("g")

vis = outer_vis.append("g")   
      .attr("transform", "translate(#{(r+p)},#{(r+p)})") # This one doesn't move. 

items = vis.selectAll("path")

partition = d3.layout.partition()
    .sort(null)
    .value((d) -> return d.depth )

    
arc = d3.svg.arc()
    .startAngle((d,i) -> 
      Math.max( 0, Math.min(2 * Math.PI, x(d.x))) 
      )
    .endAngle((d,i) -> 
      Math.max(0, Math.min(2 * Math.PI, x(d.x + d.dx)))
      )
    .innerRadius((d,i) ->
      d_y = y(d.y) ? 0
      Math.max(0, d_y)
      )
    .outerRadius((d,i) ->
      Math.max(0, y(d.y + d.dy)) 
      )


d3.json("/code_tree", (purposeCodes) -> 
  data = purposeCodes
  make_sunburst(purposeCodes)
)

make_sunburst = (purposeCodes) -> 
	nodes = partition.nodes(purposeCodes)

	items = vis.selectAll("path").data(nodes)
	 
	items.enter().append("path")
    .attr("id", (d,i) ->  
      "path-" + d.code.replace(/\./, '')
      ) # the dot messes it up
    .attr("class", "wedge")
    .attr("d", arc)
    .attr("display", (d,i) -> 
      d.depth>0 ? null : "none"; 
      ) # hide inner ring
    .style("fill", (d,i) ->  
      revColor(i)
      )
    .style("stroke", "#000")
    .style("opacity", "0")
    .style("stroke-weight", section_stroke_width+ "px")
    .style("cursor", "pointer")
    .attr('parent-code', (d) ->  
      d.parent?.code ? "" 
      )
    .attr('datum-index', (d,i) ->  i )
    .attr('datum-code', (d) ->   d.code )
    .attr('count-children', (d) ->  
      d.children?.length ? 0 
      )
    .attr('count-activities-children', (d) ->  d.all_activity_children )
    .on("click", sunburst_click)
    .on("mouseover", sunburst_mouseover)
    .on("mouseout", sunburst_mouseout)
		
    items.transition()
		  	.delay((d,i) ->  (i*(1.5)))
		  	.duration(500)
		  	.style("opacity", "1")
    

sunburst_click = (d, i) -> 
  #zoom_to_self_and_children(d, i)
  highlight_this_and_parents(d, i)
  add_text_to_this(d, i)
  #  load_detail(d, i)


highlight_this_and_parents = (d,i) -> 
  $('[highlighted=true]').attr("highlighted", "false").each(
    (j, h) -> 
      $(h)
        .css('fill', revColor($(h).attr('datum-index')))
        .css('stroke', 'black')
    )
  change_self_and_parents_of(d.code, "highlight")

default_font_size = 13
default_dy = 15
default_dy_margin = 2
add_text_to_this = (d, i) -> 
  this_path = $('#path-'+d.code.replace(/\./, ''))
  $('.code-text').remove()
  width_by_codes = d.all_activity_children
  if width_by_codes >= 6    
    allowable_width = Math.round(width_by_codes / 3) # 2:1 is ~optimal
    display_ratio = d.name.length / allowable_width

    if display_ratio < 1
      size = default_font_size
      dy = default_dy
      label = d.name
    else
      multiline_text = split_to_fit d.name, allowable_width
      console.log multiline_text
      number_of_lines = multiline_text.length
      slice_height_in_lines = d.dy * (3/.1666)
      height_ratio = slice_height_in_lines/number_of_lines
      recommended_size_by_height = height_ratio * default_font_size

      longest_line = 0
      for line in multiline_text
        if line.length > longest_line then longest_line = line.length

      length_ratio = allowable_width / longest_line
      resize_ratio = Math.min(1, length_ratio, height_ratio)
      size = resize_ratio * default_font_size
      dy  = resize_ratio * default_dy


  if label?
    text = vis.append('text')
        .attr('class', 'code-text')
        .attr("x", 2)
        .attr("dy", "#{dy}px")
        .attr("font-size", "#{size}px" )
        .attr("text-anchor", "start") 
    text.append('svg:textPath')
        .attr('xlink:href', '#path-'+d.code)
        .text(label) 
  else if multiline_text?
    for label, i in multiline_text
      text = vis.append('text')
          .attr('class', 'code-text')
          .attr("x", 2)
          .attr("dy", "#{dy +  (i*dy) }px")
          .attr("font-size", "#{size}px" )
          .attr("text-anchor", "start") 
      text.append('svg:textPath')
          .attr('xlink:href', '#path-'+d.code)
          .text(label)   

  console.log(d)
  #console.log(d.name, d.name.length, d.all_activity_children, size, display_ratio)

split_to_fit = (string, allowable_width) ->
  console.log("splitting '#{string}' to fit #{allowable_width}")
  splitters = [' ', ',', '-', '.'] # allowable splitters
  new_strings = []
  for w in [allowable_width..0]
    #console.log("trying width=#{w}, which returns '#{string[w]}'")
    if string[w] in splitters
      console.log("found a splitter at #{w} in #{string}")
      if string[w] is ' '
        end_of_word = w-1
      else 
        end_of_word = w
      new_strings.push string[0..end_of_word]
      shorter_string = string[w+1..]
      if shorter_string.length > allowable_width
        next_split = split_to_fit(shorter_string, allowable_width)
        console.log("split_to_fit is joining in", next_split, " to ", new_strings)
        new_strings = new_strings.concat(next_split)
        console.log("after joining in", next_split, ", split_to_fit has ", new_strings)
      else 
        new_strings.push shorter_string
      break
    else if w is 0
      # If you didn't find a break on the inside, 
      # then get desperate and search for a break on the outside.
      for w2 in [0..string.length]
        if string[w2] in splitters
          if string[w2] is ' '
            end_of_word = w2-1
          else 
            end_of_word = w2
          new_strings.push string[0..end_of_word]
          shorter_string = string[w2+1..] 
          if shorter_string.length > allowable_width
            next_split = split_to_fit(shorter_string, allowable_width)
            console.log("split_to_fit is joining in", next_split, " to ", new_strings)
            new_strings = new_strings.concat(next_split)
            console.log("after joining in", next_split, ", split_to_fit has ", new_strings)
          else 
            new_strings.push shorter_string
          break   
        else if w2 == string.length 
          # If you still don't find one, then return the string without a break.
          console.log("no split found in '#{string}', returning it anyways!")
          new_strings.push string
  console.log('split_to_fit is returning', new_strings)
  return new_strings
      

appropriate_text_size = (d, i) -> 
  size = "#{Math.min(Math.round( (14) * ( d.all_activity_children/d.name.length ) ), 14)}px"
  console.log(size)
  size

zoom_to_self_and_children = (d, i) -> 
  this_path = $('#path-'+d.code.replace(/\./, ''))
  this_centroid = arc.centroid(d)
  #  Just to see where it ~should~ zoom
  vis.append('circle')
    .attr('cx', this_centroid[0])
    .attr('cy', this_centroid[1])
    .attr('r', '5px')
    .attr('fill', '#f00')
    .append('title')
      .text(d.name)

  #Position.translate[0] = -(this_centroid[0]/(Position.scale)) # (-(Position.translate[0] + (this_centroid[0])))*Position.scale
  #Position.translate[1] = -(this_centroid[1]/(Position.scale)) #  (-(Position.translate[1] + (this_centroid[1])))*Position.scale
  
  zoom.scale(Position.scale).translate(Position.translate)
  console.log("click", Position.translate, Position.scale, "centroid:", this_centroid)
  # outer_vis.transition().duration(duration/2)
  #  .attr('transform', "translate(#{Position.translate}) scale(#{Position.scale})")


left_panel = (d, i) -> 
	$('#tooltiptext').text(d.name)



change_self_and_parents_of = (code, alteration) -> 
  this_path = $('#path-'+code.replace(/\./, ''))
  original_color = d3.rgb(revColor(parseInt(this_path.attr('datum-index'))))
  if alteration=='highlight'
      this_path
        .attr("highlighted", "true")
        .css("fill", original_color.brighter().brighter())
        .css("stroke", "white")
  else if (alteration=='brighter'&& this_path.attr("highlighted")!="true")
      this_path
        .css("fill", original_color.brighter())
        .css("stroke", "white")
  else if (alteration == 'original' && this_path.attr("highlighted")!="true")
    this_path
    .css("fill", original_color)
    .css("stroke", "black") 
  if (this_path.attr("parent-code").length > 0) 
    change_self_and_parents_of(this_path.attr("parent-code"), alteration)
  
sunburst_mouseover = (d,i) -> 
  $('#tooltip').show()
  change_self_and_parents_of(d.code, "brighter")
  left_panel(d,i)

sunburst_mouseout = (d,i) -> 
  change_self_and_parents_of(d.code, "original")
  d3.select(this).style('stroke', '#000')
  $('#tooltip').hide()

# Get mouse position and move tooltip
updateMousePosition = (event) -> 
  mousePosition = {left: event.pageX, top: event.pageY}
  $('div#tooltip').css('left',mousePosition.left + 20)
  $('div#tooltip').css('top',mousePosition.top-10) 

$(() -> $(document).mousemove(updateMousePosition))
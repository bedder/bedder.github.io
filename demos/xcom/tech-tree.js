function Node(name, depends, gives, level, owned) {
  this.name = name;      
  this.depends = depends;
  this.gives = gives;
  this.level = level;
  this.owned = owned;

	this.x = null;
	this.y = null;

  this.rect = null;
  this.hover = null;
  this.arcs = new Array();
}

Node.prototype.toString = function NodeToString() {
    return "[Node: " + this.name +
           ", level: " + this.level.toString() +
           ", owned: " + this.owned.toString() + "]";
}

function HighlightRequiredNodes(source, nodes, select) {
  var node_thickness;
  var arc_thickness;
  var node_colour;
  var arc_colour;

  if(select) {
    node_thickness = 5;
    arc_thickness = 5;
    node_colour = 'red';
    arc_colour = 'red';
  } else {
    node_thickness = 3;
    arc_thickness = 3;
    node_colour = 'black';
    arc_colour = 'black';
  }

  var required_nodes = [source];
  var nodes_stack = [source];

  while(nodes_stack.length != 0) {
    for(dep in nodes[nodes_stack[0]].depends) {
      var target = nodes[nodes_stack[0]].depends[dep];
      if(!nodes[target].owned && required_nodes.indexOf(nodes[target]) < 0) {
        required_nodes.push(target);
        nodes_stack.push(target);
      }
    }
    nodes_stack.splice(0, 1);
  }

  for(n in required_nodes) {
    var node = required_nodes[n];
    nodes[node].rect.attr({ 'stroke': node_colour,
                            'stroke-width': node_thickness });
    for(arc in nodes[node].arcs) {
      if(required_nodes.indexOf(arc) >= 0) {
        nodes[node].arcs[arc].attr({ 'stroke': arc_colour,
                                     'stroke-width': arc_thickness });
      }
    }
  }
}

function ColourNodes(nodes) {
  var node_colour;

  for(var node in nodes) {
    if(nodes[node].owned) {
      node_colour = 'green';
    } else {
      var leaf = true;
      for(var dep in nodes[node].depends) {
        if(!nodes[nodes[node].depends[dep]].owned) {
          leaf = false;
          break;
        }
      }
      if(leaf) {
        node_colour = 'yellow';
      } else {
        node_colour = 'red';
      }
    }
    nodes[node].hover.attr({ 'fill': node_colour });
  }
}

function DrawCanvas(paper, nodes) {
  var box_width = 250;
  var box_height = 50;
  var box_space_x = 50;
  var box_space_y = 20; // Also in InitTechnologies()

  var text_init_space_x = 7;
  var text_init_space_y = 15;
  var text_line_space = 10;

  var node_thickness = 3;
  var node_indirect = 5;
  var node_select_thickness = 7;
  var node_hover_thickness = 10;
  var arc_thickness = 3;
  var arc_select = 5;
  var arc_hover_thickness = 10;

  // Draw nodes
  for(node in nodes) {
    nodes[node].rect = paper.rect(nodes[node].x,
                                  nodes[node].y,
                                  box_width, box_height)
                             .attr({ 'stroke-width': node_thickness,
                                     'stroke-linejoin': 'round' });
    paper.text(nodes[node].x + (box_width / 2),
               nodes[node].y + text_init_space_y,
               node)
         .attr({ 'text-anchor': 'middle',
                 'font-family': '"Hind", sans-serif',
                 'font-weight': 700,
                 'font-size': '15px' });
    paper.text(nodes[node].x + text_init_space_x,
               nodes[node].y + text_init_space_y + text_line_space,
               node)
         .attr({ 'text-anchor': 'start',
                 'font-family': '"Hind", sans-serif',
                 'font-weight': 400 });
  }

  // Draw arcs
  for(from in nodes) {
    for(dep in nodes[from].depends) {
      to = nodes[from].depends[dep];
      nodes[from].arcs[to] = paper.path([ 'M', nodes[from].x,
                                               nodes[from].y + (box_height / 2),
                                          'L', nodes[to].x + box_width,
                                               nodes[to].y + (box_height / 2)])
                                  .attr({ 'stroke-width': arc_thickness });
      paper.path([ 'M', nodes[from].x,
                        nodes[from].y + (box_height / 2),
                   'L', nodes[to].x + box_width,
                        nodes[to].y + (box_height / 2)])
           .attr({ 'stroke': 'blue',
                   'stroke-width': arc_hover_thickness,
                   'stroke-opacity': 0.1})
           .hover(
             function () {
               var from = this[0];
               var to = this[1];
               nodes[from].arcs[to].attr({ 'stroke-width': arc_select });
               nodes[from].rect.attr({ 'stroke-width': node_indirect });
               nodes[to].rect.attr({ 'stroke-width': node_indirect });
             }, function () {
               var from = this[0];
               var to = this[1];
               nodes[from].arcs[to].attr({ 'stroke-width': arc_thickness });
               nodes[from].rect.attr({ 'stroke-width': node_thickness });
               nodes[to].rect.attr({ 'stroke-width': node_thickness });
             },
             [from, to], [from, to]);
    }
  }

  for(node in nodes) {
    nodes[node].hover = paper.rect(nodes[node].x - (node_hover_thickness / 2),
                                   nodes[node].y - (node_hover_thickness / 2),
                                   box_width + node_hover_thickness,
                                   box_height + node_hover_thickness);
    nodes[node].hover.attr({ 'stroke': 'none',
                             'fill': 'red',
                             'opacity': 0.1 })
                     .hover(
                       function () {
                         if(nodes[this].owned) {
                           nodes[this].rect.attr({ 'stroke-width': node_select_thickness });
                         } else {
                           HighlightRequiredNodes(this, nodes, true);
                         }
                       }, function () {
                         HighlightRequiredNodes(this, nodes, false);
                       },
                       node, node)
                     .click(
                       function() {
                         nodes[this.node.id].owned = !nodes[this.node.id].owned;
                         ColourNodes(nodes);
                     });

    nodes[node].hover.node.id = node;
  }
  ColourNodes(nodes);
}

function GetNodeData() {
  var req = new XMLHttpRequest();
  req.onload = NodeData_Listener;
  req.open("get", "longwar-tree.json", true);
  req.send();
}

function NodeData_Listener(e) {

  var box_width = 250;
  var box_height = 50;
  var box_space_x = 50;
  var box_space_y = 20; // Also in DrawCanvas()

  var raw_nodes = JSON.parse(this.responseText);
  var nodes = new Array();

  for(i in raw_nodes) {
    nodes[raw_nodes[i].name] = new Node(raw_nodes[i].name,
raw_nodes[i].depends,
raw_nodes[i].gives,
raw_nodes[i].level,
raw_nodes[i].owned); 
  }


  // Validate tree
  for(var node in nodes) {
    if(nodes[node].name != node) {
      alert("Invalid label for Node " + node + "/" + nodes[node].name);
      throw { name: 'FatalError',
              message: 'Tree structure appears to be invalid.'};
    }
    
    for(var dep in nodes[node].depends) {
      if(nodes[nodes[node].depends[dep]] == null) {
        alert("Invalid depends for Node " + node +
              " (" + nodes[node].depends[dep] + ")");

      }
    }
  }

  // Set up aux variables for spacing
  var size_array = new Array();

  for(var i=0 ; i<10 ; i++) {
    size_array[i] = 0;
  }

  for(node in nodes) {
    var level = nodes[node].level;
    nodes[node].x = (level * box_width) +
                    ((level + 1) * box_space_x);
    nodes[node].y = (size_array[level] * box_height) +
                    ((size_array[level] + 1) * box_space_y);
    size_array[level] = size_array[level] + 1;
  }

  DrawCanvas(paper, nodes);

  return nodes;
}

// Set up drawing environment
var paper;
var nodes;

window.onload = function() {
  paper = new Raphael(document.getElementById("canvas-container"), 10000, 500);
  nodes = GetNodeData();
  DrawCanvas(paper, nodes);
}



InstallMethod( SetVertexCoordiantes3DNC,
    "for a list of coordinates and a record",
    [IsDenseList, IsRecord],
    function(coordinates, printRecord)
				printRecord.vertexCoordinates3D := coordinates;
				return printRecord;
    end
);

BindGlobal( "__SIMPLICIAL_TestCoordinatesFormat",
    function(surface, coordinates)
        if Length(coordinates) <> NumberOfVertices(surface) then
          return false;
				fi;
 			if not ForAll(coordinates, IsDenseList) then
          return false;
				fi;
				return AsSet( List(coordinates, c -> Length(c))) = AsSet( [3] );
    end
);

InstallMethod( SetVertexCoordiantes3D,
    "for a polygonal complex without edge ramifications, a list of coordinates and a record",
    [IsPolygonalComplex and IsNotEdgeRamified, IsDenseList, IsRecord],
    function(surface, coordinates, printRecord)
				if not __SIMPLICIAL_TestCoordinatesFormat(surface, coordinates) then
					Error( " invalid coordinate format " );
				fi;
				return SetVertexCoordiantes3DNC(coordinates, printRecord);
    end
);

InstallOtherMethod( SetVertexCoordiantes3DNC,
    "for a list of coordinates",
    [IsDenseList],
    function(coordinates)
				return SetVertexCoordiantes3DNC(coordinates, rec());
    end
);

InstallOtherMethod( SetVertexCoordiantes3D,
    "for a polygonal complex without edge ramifications and a list of coordinates",
    [IsPolygonalComplex and IsNotEdgeRamified, IsDenseList],
    function(surface, coordinates)
				return SetVertexCoordiantes3D(surface, coordinates, rec());
    end
);

InstallMethod( GetVertexCoordiantes3DNC,
    "for a record and an index",
    [IsRecord, IsCyclotomic],
    function(printRecord, index)
				return printRecord.vertexCoordinates3D[index];
    end
);

InstallMethod( GetVertexCoordiantes3D,
    "for a polygonal complex without edge ramifications, a record and an index",
    [IsPolygonalComplex and IsNotEdgeRamified, IsRecord, IsCyclotomic],
    function(surface, printRecord, index)
				if not __SIMPLICIAL_TestCoordinatesFormat(surface, printRecord.vertexCoordinates3D) then
					Error( " invalid coordinate format " );
				fi;
				return GetVertexCoordiantes3DNC(printRecord, index);
    end
);

InstallMethod( CalculateParametersOfInnerCircle,
    "for a polygonal complex without edge ramifications and a record",
    [IsPolygonalComplex and IsNotEdgeRamified, IsRecord],
    function(surface, printRecord)
				local norm, distance, normalize, crossProd, Atan2, res, vertOfFace, P1, P2, P3,
					d1, d2, d3, incenter, s, radius, x, y, z, alpha, beta, gamma;
				if not __SIMPLICIAL_TestCoordinatesFormat(surface, printRecord.vertexCoordinates3D) then
					Error( " invalid coordinate format " );
				fi;
				norm:=function(v) return Sqrt( v[1]*v[1] + v[2]*v[2] + v[3]*v[3] ); end;
				distance:=function(p,q) return norm(p-q); end;
				normalize:=function(v) return v/norm(v); end;
				crossProd:=function(v,w) return [ v[2]*w[3]-v[3]*w[2], v[3]*w[1]-v[1]*w[3], v[1]*w[2]-v[2]*w[1] ]; end;
				Atan2:=function(y,x)
					if x > 0. then
						return Atan(y/x);
					fi;
					if x < 0. then
						if y > 0. then
							return Atan(y/x)+4*Atan(1.0);
						fi;
						if y = 0. then
							return 4*Atan(1.0);
						fi;
						return Atan(y/x)-4*Atan(1.0);
					fi;
					if y > 0. then
						return 2*Atan(1.0);
					fi;
					if y < 0. then
						return -2*Atan(1.0);
					fi;
					return 0.;
				end;
				res := [];
				for vertOfFace in VerticesOfFaces(surface) do
					if Length(vertOfFace) <> 3 then
						Append(res, [[]]);
						continue;
					fi;
					P1 := printRecord.vertexCoordinates3D[vertOfFace[1]];
					P2 := printRecord.vertexCoordinates3D[vertOfFace[2]];
					P3 := printRecord.vertexCoordinates3D[vertOfFace[3]];
					# calculate distances
					d1 := distance(P2,P3);
					d2 := distance(P1,P3);
					d3 := distance(P1,P2);
					# calculate coordiantes of incenter
					incenter := ( d1*P1 + d2*P2 + d3*P3 ) / ( d1 + d2 + d3 );
					# calculate radius
					s := ( d1 + d2 + d3 ) / 2;
					radius := Sqrt( s * ( s - d1 ) * ( s - d2 ) * ( s - d3 ) ) / s;
					# calculate rotation angles (from x-y-plane)
					z := normalize(crossProd( P2-P1, P3-P1 ));
					x := normalize((P1+P2)/2 - P3);
					y := crossProd(z, x);
					alpha := Atan2(-z[2], z[3]);
					beta := Asin(z[1]);
					gamma := Atan2(-y[1], x[1]);
					Append(res, [ [incenter, radius, [ alpha, beta, gamma ] ] ]);
				od;
				printRecord.innerCircles := res;
				return printRecord;
    end
);

InstallMethod( ActivateInnerCircle,
    "for a record",
    [IsRecord],
    function(printRecord)
				if not IsBound(printRecord.innerCircles) then
					Error(" The parameters of the innercircles are not set ");
				fi;
				printRecord.drawInnerCircles := true;
				return printRecord;
    end
);

InstallMethod( DeactivateInnerCircle,
    "for a record",
    [IsRecord],
    function(printRecord)
				printRecord.drawInnerCircles := false;
				return printRecord;
    end
);

InstallMethod( IsInnerCircleActive,
    "for a record",
    [IsRecord],
    function(printRecord)
				if not IsBound(printRecord.innerCircles) then
					return false;
				fi;
				return printRecord.drawInnerCircles;
    end
);

InstallMethod( CalculateParametersOfEdges,
    "for a polygonal complex without edge ramifications and a record",
    [IsPolygonalComplex and IsNotEdgeRamified, IsRecord],
    function(surface, printRecord)
				local norm, distance, Atan2, res, vertOfEdge, P1, P2, d, mid, beta, gamma;
				if not __SIMPLICIAL_TestCoordinatesFormat(surface, printRecord.vertexCoordinates3D) then
					Error( " invalid coordinate format " );
				fi;
				norm:=function(v) return Sqrt( v[1]*v[1] + v[2]*v[2] + v[3]*v[3] ); end;
				distance:=function(p,q) return norm(p-q); end;
				Atan2:=function(y,x)
					if x > 0. then
						return Atan(y/x);
					fi;
					if x < 0. then
						if y > 0. then
							return Atan(y/x)+4*Atan(1.0);
						fi;
						if y = 0. then
							return 4*Atan(1.0);
						fi;
						return Atan(y/x)-4*Atan(1.0);
					fi;
					if y > 0. then
						return 2*Atan(1.0);
					fi;
					if y < 0. then
						return -2*Atan(1.0);
					fi;
					return 0.;
				end;
				res := [];
				for vertOfEdge in VerticesOfEdges(surface) do
					P1 := printRecord.vertexCoordinates3D[vertOfEdge[1]];
					P2 := printRecord.vertexCoordinates3D[vertOfEdge[2]];
					# calculate distance
					d := distance(P1,P2);
					# calculate coordiantes of mid of edge
					mid := ( P1 + P2 ) / 2;
					# calculate rotation angles (from y-direction)
					beta := Atan2(-1.0*(P2[3]-P1[3]), 1.0*(P2[1]-P1[1]));
					gamma := -Acos(1.0*(P2[2]-P1[2])/d);
					Append(res, [ [mid, d, [ 0., beta, gamma ] ] ]);
				od;
				printRecord.edges := res;
				return printRecord;
    end
);

InstallMethod( SetFaceColour,
    "for an index, a string and a record",
    [IsCyclotomic, IsString, IsRecord],
    function(index, colour, printRecord)
				if not IsBound(printRecord.faceColours) then
					printRecord.faceColours := [];
				fi;
				printRecord.faceColours[index] := colour;
				return printRecord;
    end
);

InstallMethod( GetFaceColour,
    "for an index and a record",
    [IsCyclotomic, IsRecord],
    function(index, printRecord)
				local default;
				default := "0xFFFF00";
				if not IsBound(printRecord.faceColours) or (index <= 0) then
					return default;
				fi;
				if not IsBound(printRecord.faceColours[index]) then
					return default;
				fi;
				return printRecord.faceColours[index];
    end
);

InstallMethod( SetFaceColours,
    "for a list and a record",
    [IsDenseList, IsRecord],
    function(faceColours, printRecord)
				printRecord.faceColours := faceColours;
				return printRecord;
    end
);

InstallMethod( GetFaceColours,
    "for a record",
    [IsRecord],
    function(printRecord)
				if not IsBound(printRecord.faceColours) then
					return [];
				fi;
				return printRecord.faceColours;
    end
);

InstallMethod( SetVertexColour,
    "for an index, a string and a record",
    [IsCyclotomic, IsString, IsRecord],
    function(index, colour, printRecord)
				if not IsBound(printRecord.vertexColours) then
					printRecord.vertexColours := [];
				fi;
				printRecord.vertexColours[index] := colour;
				return printRecord;
    end
);

InstallMethod( GetVertexColour,
    "for an index and a record",
    [IsCyclotomic, IsRecord],
    function(index, printRecord)
				local default;
				default := "0xF58137";
				if not IsBound(printRecord.vertexColours) or (index <= 0) then
					return default;
				fi;
				if not IsBound(printRecord.vertexColours[index]) then
					return default;
				fi;
				return printRecord.vertexColours[index];
    end
);

InstallMethod( SetVertexColours,
    "for a list and a record",
    [IsDenseList, IsRecord],
    function(vertexColours, printRecord)
				printRecord.vertexColours := vertexColours;
				return printRecord;
    end
);

InstallMethod( GetVertexColours,
    "for a record",
    [IsRecord],
    function(printRecord)
				if not IsBound(printRecord.vertexColours) then
					return [];
				fi;
				return printRecord.vertexColours;
    end
);

InstallMethod( SetEdgeColour,
    "for an index, a string and a record",
    [IsCyclotomic, IsString, IsRecord],
    function(index, colour, printRecord)
				if not IsBound(printRecord.edgeColours) then
					printRecord.edgeColours := [];
				fi;
				printRecord.edgeColours[index] := colour;
				return printRecord;
    end
);

InstallMethod( GetEdgeColour,
    "for an index and a record",
    [IsCyclotomic, IsRecord],
    function(index, printRecord)
				local default;
				default := "0xff0000";
				if not IsBound(printRecord.edgeColours) or (index <= 0) then
					return default;
				fi;
				if not IsBound(printRecord.edgeColours[index]) then
					return default;
				fi;
				return printRecord.edgeColours[index];
    end
);

InstallMethod( SetEdgeColours,
    "for a list and a record",
    [IsDenseList, IsRecord],
    function(edgeColours, printRecord)
				printRecord.edgeColours := edgeColours;
				return printRecord;
    end
);

InstallMethod( GetEdgeColours,
    "for a record",
    [IsRecord],
    function(printRecord)
				if not IsBound(printRecord.EdgeColours) then
					return [];
				fi;
				return printRecord.EdgeColours;
    end
);

InstallMethod( SetCircleColour,
    "for an index, a string and a record",
    [IsCyclotomic, IsString, IsRecord],
    function(index, colour, printRecord)
				if not IsBound(printRecord.circleColours) then
					printRecord.circleColours := [];
				fi;
				printRecord.circleColours[index] := colour;
				return printRecord;
    end
);

InstallMethod( GetCircleColour,
    "for an index and a record",
    [IsCyclotomic, IsRecord],
    function(index, printRecord)
				local default;
				default := "0x000000";
				if not IsBound(printRecord.circleColours) or (index <= 0) then
					return default;
				fi;
				if not IsBound(printRecord.circleColours[index]) then
					return default;
				fi;
				return printRecord.circleColours[index];
    end
);

InstallMethod( SetCircleColours,
    "for a list and a record",
    [IsDenseList, IsRecord],
    function(circleColours, printRecord)
				printRecord.circleColours := circleColours;
				return printRecord;
    end
);

InstallMethod( GetCircleColours,
    "for a record",
    [IsRecord],
    function(printRecord)
				if not IsBound(printRecord.circleColours) then
					return [];
				fi;
				return printRecord.circleColours;
    end
);

# general method
InstallMethod( DrawSurfaceToJavaScript, 
    "for a polygonal complex without edge ramifications, a filename and a record",
    [IsPolygonalComplex and IsNotEdgeRamified, IsString, IsRecord],
    function(surface, fileName, printRecord)
				local file, output, template, coords, i, colour, vertOfFace, vertOfEdge, parametersOfCircle, parametersOfEdge;

        # Make the file end with .html
        if not EndsWith( fileName, ".html" ) then
            fileName := Concatenation( fileName, ".html" );
        fi;

        # Try to open the given file
        file := Filename( DirectoryCurrent(), fileName ); #TODO allow absolute paths
        output := OutputTextFile( file, false ); # override other files
        if output = fail then
            Error(Concatenation("File ", String(file), " can't be opened.") );
        fi;
        SetPrintFormattingStatus( output, false );

				template := __SIMPLICIAL_ReadTemplateFromFile("/pkg/simplicial-surfaces/doc/JS_Header.html.template");
				AppendTo( output, template );

        # Set coordinates of vertices
        if not __SIMPLICIAL_TestCoordinatesFormat(surface, printRecord.vertexCoordinates3D) then
					Error( " invalid coordinate format " );
				fi;
				for i in [1..NumberOfVertices(surface)] do
					coords := GetVertexCoordiantes3DNC(printRecord, i);
					AppendTo(output, "\t\tallpoints.push(new PMPoint(", coords[1], ",", coords[2], ",", coords[3], "));\n");
				od;

        # Add points to scenario
				for i in [0..(NumberOfVertices(surface)-1)] do
					colour := GetVertexColour(i+1, printRecord);
					AppendTo(output, "\t\tvar points_material", i, " = new THREE.MeshBasicMaterial( {color: ", colour, " } );\n");
					AppendTo(output, "\t\tpoints_material", i, ".side = THREE.DoubleSide;\n");
					AppendTo(output, "\t\tpoints_material", i, ".transparent = true;\n");
					AppendTo(output, "\t\t// draw a node as a sphere of radius 0.05\n");
					AppendTo(output, "\t\tallpoints[", i, "].makesphere(0.05,points_material", i, ");\n");
					AppendTo(output, "\t\tallpoints[", i, "].makelabel(", i+1, ");\n");
				od;
				template := __SIMPLICIAL_ReadTemplateFromFile("/pkg/simplicial-surfaces/doc/JS_associate_points_init_faces.html.template");
				AppendTo( output, template );
				for i in [0..(NumberOfVertices(surface)-1)] do
					AppendTo(output, "\t\tfaces.vertices.push(allpoints[", i, "].vector);\n");
				od;

				# Add Faces to scenario
				template := __SIMPLICIAL_ReadTemplateFromFile("/pkg/simplicial-surfaces/doc/JS_faces_material.html.template");
				AppendTo( output, template );
				for i in [1..(NumberOfFaces(surface))] do
					vertOfFace := VerticesOfFaces(surface)[i];
					colour := GetFaceColour(i, printRecord);
					AppendTo(output, "\t\tfaces.faces.push(new THREE.Face3(", vertOfFace[1]-1, ",", vertOfFace[2]-1, ",", vertOfFace[3]-1, ",undefined, undefined, 0));\n");
				od;
				template := __SIMPLICIAL_ReadTemplateFromFile("/pkg/simplicial-surfaces/doc/JS_add_faces.html.template");
				AppendTo( output, template );

				if IsInnerCircleActive(printRecord) then
					if not IsBound(printRecord.innerCircles) then
						printRecord := CalculateParametersOfInnerCircle(surface, printRecord);
					fi;
					AppendTo(output, "\n\n");
					for i in [1..(NumberOfFaces(surface))] do
						parametersOfCircle := printRecord.innerCircles[i];
						colour := GetCircleColour(i, printRecord);
						AppendTo(output, "\t\tvar circle = Circle(", parametersOfCircle[2], ", ", parametersOfCircle[1][1], ", ",
							parametersOfCircle[1][2], ", ", parametersOfCircle[1][3], ", ", parametersOfCircle[3][1], ", ",
							parametersOfCircle[3][2], ", ", parametersOfCircle[3][3], ", ", colour, ");\n");
						AppendTo(output, "\t\tobj.add(circle);\n");
					od;
					AppendTo(output, "\n\n");
				fi;

				# Add Edges to scenario
				template := __SIMPLICIAL_ReadTemplateFromFile("/pkg/simplicial-surfaces/doc/JS_init_edges.html.template");
				AppendTo( output, template );
				if not IsBound(printRecord.edges) then
					printRecord := CalculateParametersOfEdges(surface, printRecord);
				fi;
				for i in [1..(NumberOfEdges(surface))] do
					parametersOfEdge := printRecord.edges[i];
					colour := GetEdgeColour(i, printRecord);
					AppendTo(output, "\t\tvar edge = Edge(", parametersOfEdge[2], ", ", parametersOfEdge[1][1], ", ",
						parametersOfEdge[1][2], ", ", parametersOfEdge[1][3], ", ", parametersOfEdge[3][1], ", ",
						parametersOfEdge[3][2], ", ", parametersOfEdge[3][3], ", ", colour, ");\n");
					AppendTo(output, "\t\tobj.add(edge);\n");
				od;

				template := __SIMPLICIAL_ReadTemplateFromFile("/pkg/simplicial-surfaces/doc/JS_Footer.html.template");
				AppendTo( output, template );

				CloseStream(output);
        return printRecord;
    end
);

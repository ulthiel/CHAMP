
E := func<n | RootOfUnity(n)>;

groups := [];

for i:=2 to 22 do
    print i;
    
    //Gi
    Gmat := eval Read("GAP3_Data/G"*Sprint(i));
    Gpre := MatrixGroup(Gmat);
    G := MatrixGroup<Dimension(Gpre), BaseRing(Gpre) | [ Transpose(Gpre.i) : i in [1..Ngens(Gpre)]]>;

    str := "/*";
    str *:= "\n";
    str *:= "    Symmetric reflection group S"*Sprint(i)*" as obtained from the transposed of ComplexReflectionGroup(1,1,"*Sprint(i)*") in GAP3-jm5.";
    str *:= "\n\n";
    str *:= "    Date: "*Date();
    str *:= "\n";
    str *:= "*/\n"; 
  
    str *:= Sprint(G, "Magma");
    
    CHAMP_SaveToDB(str, "ReflectionGroups/S"*Sprint(i)*"_CHEVIE", "GrpMat");
        
    //dual of Gi
    str := "/*";
    str *:= "\n";
    str *:= "    Dual of symmetric reflection group S"*Sprint(i)*" as obtained from the transposed of ComplexReflectionGroup(1,1,"*Sprint(i)*") in GAP3-jm5.";
    str *:= "\n\n";
    str *:= "    Date: "*Date();
    str *:= "\n";
    str *:= "*/\n"; 
  
    str *:= Sprint(DualGroup(G), "Magma");
    
    CHAMP_SaveToDB(str, "ReflectionGroups/S"*Sprint(i)*"_CHEVIE_Dual", "GrpMat");
       
    //character data of Si
    Cpre := eval Read("GAP3_Data/C"*Sprint(i));
    C := [ Reverse(Cpre[j]) : j in [1..#Cpre] ]; //classes
    X := eval Read("GAP3_Data/X"*Sprint(i)); //character table
    N := eval Read("GAP3_Data/XN"*Sprint(i)); //character names
    
    //rewrite N
    for i:=1 to #N do
        str := N[i];
        str := Replace(str, "{", "_{");
        str := Replace(str, "phi", "\\phi");
        N[i] := str;
    end for;
    
    str := "/*";
    str *:= "\n";
    str *:= "    Character data of symmetric reflection group S"*Sprint(i)*" as obtained by reversing the lists in WordsClassRepresentatives in GAP3-jm5 (Reversing because we transposed the group!), using CharTable, and using CharNames.";
    str *:= "\n\n";
    str *:= "    Date: "*Date();
    str *:= "\n";
    str *:= "*/\n";
    
    str *:= Sprint(<C,X,N>, "Magma");

    CHAMP_SaveToDB(str, "ReflectionGroups/S"*Sprint(i)*"_CHEVIE", "CharacterData");
    
    //fakes
    P<q>:=PolynomialRing(Integers());
    fakes := eval Read("GAP3_Data/fake"*Sprint(i));
    
    str := "P<q>:=PolynomialRing(Integers());\n";
    str *:= "return \n";
    str *:= Sprint(fakes);
    
    CHAMP_SaveToDB(str, "ReflectionGroups/S"*Sprint(i)*"_CHEVIE", "FakeDegrees");

	//reps
	if i lt 10 then
        //Gi
        Rpre := eval Read("GAP3_Data/R"*Sprint(i));
        R := [* *];
        for j:=1 to #Rpre do
            entries := SequenceToSet(Flat(Rpre[j]));
            K := MinimalCyclotomicField(entries);
            mats := [ Transpose(Matrix(K, Rpre[j][k])) : k in [1..Ngens(G)] ];
            Append(~R, mats);
        end for;

        str := "/*";
        str *:= "\n";
        str *:= "    Transposed of irreducible representations of symmetric reflection group S"*Sprint(i)*" as obtained by Representations in GAP3-jm5.";
        str *:= "\n\n";
        str *:= "    Date: "*Date();
        str *:= "\n";
        str *:= "*/\n";
         
        str *:= Sprint(R, "Magma");    
    
        CHAMP_SaveToDB(str, "ReflectionGroups/S"*Sprint(i)*"_CHEVIE", "Representations_0");
    end if;

end for;


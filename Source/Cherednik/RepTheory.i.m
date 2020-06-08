/*
  CHAMP (CHerednik Algebra Magma Package)
  Copyright (C) 2013–2020 Ulrich Thiel
  Licensed under GNU GPLv3, see COPYING.
  https://github.com/ulthiel/champ
  thiel@mathematik.uni-kl.de
*/

/*
	Representation theory of restricted rational Cherednik algebras
*/


declare attributes AlgCheRes:
	CommutatorVectorsTable,
	GradedCharactersOfVermas,
	GradedCharactersOfSimples,
	GradedDecompositionMatrix,
	GradedCartanMatrix,
	VermaModules,
	SimpleModules,
	PoincareSeriesOfSimples;



//============================================================================
intrinsic VermaModule(H::AlgCheRes, rho::HomGrp : Rep:="Sparse",  Verbose:=true) -> ModGrOld
{
	The Verma module for rho for the restricted rational Cherednik algebra H.
}

	//We compute here Delta(rho) = K[V]_G \otimes rho as in [BR] or in [Thi15].

  if Rep ne "Sparse" and Rep ne "Dense" then
  	error "Rep has to be one of \"Sparse\" (default) or \"Dense\".";
  end if;

	Initialize(~H);

	W := H`Group;

	//we need a monomial basis of the coinvariant algebra which is sorted by degree, otherwise things will mess up. we check this here even though Basis will do this automatically.
	if exists{f : f in W`CoinvariantAlgebra`Basis | IsMonomial(f) eq false} then
		error "Basis of the coinvariant algebra has to be a monomial basis.";
	end if;

	//check if bases are compatible
	if not H`xAlgebra`Basis eq {@ H`CoinvariantAlgebraToxAlgebra(b) : b in W`CoinvariantAlgebra`Basis @} then
		error "Bases of coinvariant algebra and xAlgebra are not equal.";
	end if;

	//G-action on coinvariant algebra
	CoinvariantAlgebraGradedGModule(~W : Rep:=Rep, Verbose:=Verbose);

	//coinvariant algebra as a module over itself
	CoinvariantAlgebraGradedModule(~W : Rep:=Rep, Verbose:=Verbose);

	//some variables
	A := W`CoinvariantAlgebra;
	AW := W`CoinvariantAlgebraGradedGModule;
	AA := W`CoinvariantAlgebraGradedModule;
	Adim := Dimension(A);
	rhodim := Ncols(rho(W.1));
	Wdim := Dimension(W);
	Worder := Order(W);
	R := Codomain(H`cParameter);
	V := VectorSpace(W);

	rhospace := VectorSpace(R, rhodim); //space on which rho acts (extended to R)

	//generator gradings (w,y,x)
	alggrading := [ 0 : i in [1..Ngens(W)] ] cat [ -1 : i in [1..Wdim] ] cat [ 1 : i in [1..Wdim] ];

	//initialize matrices
	if Rep eq "Dense" then
		opmats := [* <i,d,ZeroMatrix(R,Dimension(AA`ModuleComponents[d])*rhodim,Dimension(AA`ModuleComponents[d+alggrading[i]])*rhodim)> : d in AA`Support, i in [1..#alggrading] | d+alggrading[i] in AA`Support *];
	else
		opmats := [* <i,d,SparseMatrix(R,Dimension(AA`ModuleComponents[d])*rhodim,Dimension(AA`ModuleComponents[d+alggrading[i]])*rhodim)> : d in AA`Support, i in [1..#alggrading] | d+alggrading[i] in AA`Support *];
	end if;

	//component dimensions of Verma module
	componentdimensions := [ <d,Dimension(AA`ModuleComponents[d])*rhodim> : d in AA`Support ];

	//operation matrices of rho in same type as Rep
	if Rep eq "Dense" then
		rhomats := [rho(W.i) : i in [1..Ngens(W)]];
	else
		rhomats := [SparseMatrix(rho(W.i)) : i in [1..Ngens(W)]];
	end if;

	//index blocks
	wblock := [1..Ngens(W)];
	yblock := [Ngens(W)+1..Ngens(W)+Wdim];
	xblock := [Ngens(W)+Wdim+1..Ngens(W)+2*Wdim];

	//compute action matrices of Verma module
	if Verbose then
		print "Computing Verma module.";
	end if;

	for m:=1 to #opmats do

		if Verbose then
			PrintPercentage(m, #opmats);
		end if;

		i:=opmats[m][1];	//algebra generator
		d:=opmats[m][2];	//source degree

		//g-action
		if i in wblock then
			opmats[m][3] := TensorProductMixedType( ChangeRing(AW`Matrices[i][d],R),ChangeRing(rhomats[i],R) : Rep:=Rep); //g-action on coinvariant algebra tensor g-action; it's that simple

		//x-action
		elif i in xblock then
			i:=i-Wdim-Ngens(W);	//x_i
			opmats[m][3] := TensorProductMixedType(ChangeRing(AA`Matrices[i][d],R),IdentityMatrix(R,rhodim) : Rep:=Rep); //x-action on coinvariant algebra tensor identity; it's that simple

		//y-action
		elif i in yblock then
			i:=i-Ngens(W);	//y_i
			for j:=1 to Dimension(AA`ModuleComponents[d]) do
				//action of y_i on j-th basis vector of degree d component of coinvariant algebra
				xmu := A`Basis[A`ComponentBasis[d][j]]; ////j-th basis vector of degree d component of coinvariant algebra is x^mu
				mu := Exponents(xmu);
				for r:=1 to #W`ReflectionLibraryFlat do
					v := CommutatorGradedVector(H,i,mu,r); //graded vector of [y_i,x^mu]_{s_r}; this is homogeneous of degree d-1
					if IsZero(v) then //zero vector
						continue;
					end if;
					rhos := rho(W`ReflectionLibraryFlat[r]`Element);
					for k:=1 to rhodim do
						u := TensorProduct(v, ChangeRing(rhos[k],R));
						for l in Support(u) do
							opmats[m][3][(j-1)*rhodim+k][l] +:= u[l];
						end for;
					end for;
				end for;
			end for;
		end if;

	end for;

	return GradedModuleOld(GradedModule(R, alggrading, componentdimensions, opmats : Rep:=Rep));

end intrinsic;

//============================================================================
intrinsic IsModule(H::AlgCheRes, V::ModGrOld) -> BoolElt
/*
    Intrinsic: IsModuleForRRCA

    History:
        Thursday, September 19, 2013 13:39:59: Initial.
*/
{Checks if V satisfies all relations to make it to a module for the restricted rational Cherednik algebra for G and parameter c.}

		G := H`Group;
		c := H`cParameter;
		V := RModule(V);
		matrices := ActionGenerators(V); //g, y, x
		rep := "Dense";

    FPGroup(~G);
    Gdim := Dimension(G);
    Gspace := VectorSpace(G);
    NGrels := #Relations(G`FPGroup);
    CoinvariantAlgebra(~G);
    CoinvariantAlgebra(~G`DualGroup);
    NCoinvrels := #Basis(G`HilbertIdeal);
    NDualCoinvrels := #Basis(G`DualGroup`HilbertIdeal);
    nops := 2*Gdim^2 + NGrels + 2*Gdim*Ngens(G) + Gdim*Gdim + NCoinvrels + NDualCoinvrels;

		//index blocks
		gblock := [1..Ngens(G)];
		yblock := [Ngens(G)+1..Ngens(G)+Gdim];
		xblock := [Ngens(G)+Gdim+1..Ngens(G)+2*Gdim];

    //y-y operation
    //check if y_i*y_j action is equal to y_j*y_i action
    for i in yblock do
        for j in yblock do
            if matrices[i]*matrices[j] ne matrices[j]*matrices[i] then
                print "(IsModuleForRRCA). x"*Sprint(i)*"-x"*Sprint(j)*" operation is wrong.";
                return false;
            end if;
            PrintPercentage( (i-1)*j, nops);
        end for;
    end for;

    //x-x operation
    //check if x_i*x_j action is equal to x_j*x_i action
    for i in xblock do
        for j in xblock do
            if matrices[i]*matrices[j] ne matrices[j]*matrices[i] then
                print "(IsModuleForRRCA). y"*Sprint(i)*"-y"*Sprint(j)*" operation is wrong.";
                return false;
            end if;
            PrintPercentage(Gdim^2 + (i-1)*j, nops);
        end for;
    end for;

    //g-g operations
    //check group relations (that's a bit difficult)
    relcount := 0;
    for rel in Relations(G`FPGroup) do
        relcount +:= 1;
        lhs := Eltseq(LHS(rel));
        rhs := Eltseq(RHS(rel));
        if rep eq "Sparse" then
            vermalhs := IdentitySparseMatrix(BaseRing(V), Dimension(V));
        else
            vermalhs := IdentityMatrix(BaseRing(V), Dimension(V));
        end if;
        for i:=1 to #lhs do
            if lhs[i] gt 0 then
                j := lhs[i];
                vermalhs *:= matrices[j];
            else
                j := Abs(lhs[i]);
                vermalhs *:= matrices[j]^(Order(G.j)-1);
            end if;
        end for;

        if rep eq "Sparse" then
            vermarhs := IdentitySparseMatrix(BaseRing(V), Dimension(V));
        else
            vermarhs := IdentityMatrix(BaseRing(V), Dimension(V));
        end if;
        for i:=1 to #rhs do
            if rhs[i] gt 0 then
                j := rhs[i];
                vermarhs *:= matrices[j];
            else
                j := Abs(rhs[i]);
                vermarhs *:= matrices[j]^(Order(G.j)-1);
            end if;
        end for;

        if vermalhs ne vermarhs then
            print "(IsModuleForRRCA). Group relation "*Sprint(rel)*" not respected.";
            return false;
        end if;

        PrintPercentage(2*Gdim^2 + relcount, nops);
    end for;


    //now we come to the interactions

    //x-g operation
    //check if x_i*g_j action is equal to g_j*x_i^g_j action (we're acting from the right in Magma)
    for i in xblock do
        for j in gblock do
            A := matrices[i]*matrices[j]; //x_i*g_j

            //B will be action of g_j*x_i^g_j
            if rep eq "Dense" then
                B := ZeroMatrix(BaseRing(V), Dimension(V), Dimension(V));
            else
                B := SparseMatrix(BaseRing(V), Dimension(V), Dimension(V));
            end if;
            v := (Transpose(G.j)^-1)[i-Ngens(G)-Gdim]; // action of g_j on x_i
            for k in Support(v) do
                B +:= v[k]*matrices[xblock[k]];
            end for;
            B := matrices[j]*B;
            if A ne B then
                print "(IsModuleForRRCA). x"*Sprint(i)*"-g"*Sprint(j)*" operation is wrong.";
                return false;
            end if;

            PrintPercentage(2*Gdim^2 + NGrels + (i-1)*Ngens(G), nops);
        end for;
    end for;

    //y-g operation
    //check if y_i*g_j action is equal to g_j*y_i^g_j action (we're acting from the right in Magma)
    for i in yblock do
        for j in gblock do
            A := matrices[i]*matrices[j]; //y_i*g_j

            //B will be action of g_j*y_i^g_j
            if rep eq "Dense" then
                B := ZeroMatrix(BaseRing(V), Dimension(V), Dimension(V));
            else
                B := SparseMatrix(BaseRing(V), Dimension(V), Dimension(V));
            end if;
            v := (G.j)[i-Ngens(G)]; // action of g_j on y_i
            for k in Support(v) do
                B +:= v[k]*matrices[yblock[k]];
            end for;
            B := matrices[j]*B;
            if A ne B then
                print "(IsModuleForRRCA). y"*Sprint(i)*"-g"*Sprint(j)*" operation is wrong.";
                return false;
            end if;

            PrintPercentage(2*Gdim^2 + NGrels + Gdim*Ngens(G) + (i-1)*Ngens(G), nops);
        end for;
    end for;

    //x-y operation
    //check if x_i*y_j action is equal to the [x_i,y_j]+(y_j*x_i) action (remember: we are in the opposite algebra!)
    for i in xblock do
        for j in yblock do
            B := matrices[i]*matrices[j]; //x_i*y_j
            A := matrices[j]*matrices[i]; //y_j*x_i

            //now we have to add the action of the commutator to B
            for s:=1 to #G`ReflectionLibraryFlat do
                sword := ElementToWord(G`ReflectionLibraryFlat[s]`Element); //reflection s as a word in the generators

                //matrix C will be the action of the reflection s on the module
                if rep eq "Dense" then
                    C := IdentityMatrix(BaseRing(V), Dimension(V));
                else
                    C := IdentitySparseMatrix(BaseRing(V), Dimension(V));
                end if;

                for k:=1 to #sword do
                    if sword[k] gt 0 then
                        p := sword[k];
                        C *:= matrices[p];
                    else
                        p := Abs(sword[k]);
                        C *:= matrices[p]^(Order(G.p)-1);
                    end if;
                end for;

                B -:= c(G`ReflectionLibraryFlat[s]`ReflectionClass)*CherednikCoefficient(Gspace.(j-Ngens(G)),Gspace.(i-Ngens(G)-Gdim),G`ReflectionLibraryFlat[s])*C;
            end for;

            if A ne B then
                print "(IsModuleForRRCA). x"*Sprint(i)*"-y"*Sprint(j)*" operation is wrong.";
                return false;
            end if;

            PrintPercentage(2*Gdim^2 + NGrels + 2*Gdim*Ngens(G) + (i-1)*Gdim, nops);

        end for;
    end for;

    //coinvariant algebra (x)
    relcount := 0;
    for rel in Basis(G`HilbertIdeal) do
        relcount +:= 1;
        mons := Monomials(rel);
        coeffs := Coefficients(rel);
        if rep eq "Dense" then
            A := ZeroMatrix(BaseRing(V), Dimension(V), Dimension(V));
        else
            A := SparseMatrix(BaseRing(V), Dimension(V), Dimension(V));
        end if;
        for i:=1 to #mons do
            exp := Exponents(mons[i]);
            if rep eq "Dense" then
                C := IdentityMatrix(BaseRing(V), Dimension(V));
            else
                C := IdentitySparseMatrix(BaseRing(V), Dimension(V));
            end if;
            for j:=1 to #exp do
                C *:= matrices[xblock[j]]^exp[j];
            end for;

            A +:= coeffs[i]*C;
        end for;

        if not IsZero(A) then
            print "(IsModuleForRRCA). Coinvariant algebra relations not respected.";
            return false;
        end if;

        PrintPercentage(2*Gdim^2 + NGrels + 2*Gdim*Ngens(G) + Gdim^2 + relcount, nops);

    end for;

    //dual coinvariant algebra (y)
    relcount := 0;
    for rel in Basis(G`DualGroup`HilbertIdeal) do
        relcount +:= 1;
        mons := Monomials(rel);
        coeffs := Coefficients(rel);
        if rep eq "Dense" then
            A := ZeroMatrix(BaseRing(V), Dimension(V), Dimension(V));
        else
            A := SparseMatrix(BaseRing(V), Dimension(V), Dimension(V));
        end if;
        for i:=1 to #mons do
            exp := Exponents(mons[i]);
            if rep eq "Dense" then
                C := IdentityMatrix(BaseRing(V), Dimension(V));
            else
                C := IdentitySparseMatrix(BaseRing(V), Dimension(V));
            end if;
            for j:=1 to #exp do
                C *:= matrices[yblock[j]]^exp[j];
            end for;

            A +:= coeffs[i]*C;
        end for;

        if not IsZero(A) then
            print "(IsModuleForRRCA). Dual coinvariant algebra relations not respected.";
            return false;
        end if;

        PrintPercentage(2*Gdim^2 + NGrels + 2*Gdim*Ngens(G) + Gdim^2 + NCoinvrels + relcount, nops);

    end for;

    print "Everything OK.";

    return true;

end intrinsic;

//============================================================================
intrinsic VermaModule(~H::AlgCheRes, i::RngIntElt)
{}

	W := H`Group;
	Representations(~W);
	if not assigned H`VermaModules then
		H`VermaModules := AssociativeArray({1..#W`Representations[0]});
	end if;
	if not IsDefined(H`VermaModules, i) then
		H`VermaModules[i] := VermaModule(H, W`Representations[0][i]);
	end if;

end intrinsic;

intrinsic VermaModule(H::AlgCheRes, i::RngIntElt) -> ModGrOld
{}

	VermaModule(~H,i);
	return H`VermaModules[i];

end intrinsic;

intrinsic VermaModules(~H::AlgCheRes)
{}

	W := H`Group;
	Representations(~W);
	for i:=1 to #W`Representations[0] do
		VermaModule(~H, i);
	end for;

end intrinsic;

//============================================================================
intrinsic SimpleModule(~H::AlgCheRes, i::RngIntElt)
{}

	W := H`Group;
	Representations(~W);
	if not assigned H`SimpleModules then
		H`SimpleModules := AssociativeArray({1..#W`Representations[0]});
	end if;
	if not IsDefined(H`SimpleModules, i) then
		VermaModule(~H, i);
		res,L,J,P := HeadOfLocalModule(H`VermaModules[i] : Rounds:=10);
		if res then
			H`SimpleModules[i] := L;
		end if;
	end if;

end intrinsic;

//============================================================================
intrinsic GradedCharacterOfVerma(~H::AlgCheRes, i::RngIntElt)
/*
	This uses the formula in my proceedings paper.
*/
{}
	W := H`Group;
	CharacterTable(~W);
	FakeDegrees(~W);
	N := #W`CharacterTable;
	if not assigned H`GradedCharactersOfVermas then
		H`GradedCharactersOfVermas := AssociativeArray({1..N});
	end if;
	if not IsDefined(H`GradedCharactersOfVermas, i) then
		V := KSpace(H`qField, N);
		lambda := W`CharacterTable[i];
		D := Zero(V);
		for j:=1 to N do
			mu := W`CharacterTable[j];
			fmu := W`FakeDegrees[j];
			muduallambda := V!Decomposition(W`CharacterTable, ComplexConjugate(mu)*lambda); // decomposition of mu* \otimes lambda
			D +:= fmu*muduallambda;
		end for;

		H`GradedCharactersOfVermas[i] := D;
	end if;

end intrinsic;

intrinsic GradedCharacterOfVerma(H::AlgCheRes, i::RngIntElt) -> ModTupFldElt
{}

	GradedCharacterOfVerma(~H,i);
	return H`GradedCharactersOfVermas[i];

end intrinsic;

intrinsic GradedCharactersOfVermas(~H::AlgCheRes)
{}

	W := H`Group;
	CharacterTable(~W);
	for i:=1 to #W`CharacterTable do
		GradedCharacterOfVerma(~H,i);
	end for;

end intrinsic;

intrinsic GradedCharactersOfVermas(H::AlgCheRes) -> AlgMatElt
{}

	GradedCharactersOfVermas(~H);
	N := #H`Group`CharacterTable;
	CDelta := Matrix(H`qField, N, N, [GradedCharacterOfVerma(H,i) : i in [1..N]]);
	return CDelta;

end intrinsic;



//============================================================================
intrinsic GradedCharacter(H::AlgCheRes, M::ModGrOld) -> ModRngElt
{}

	W := H`Group;
	CharacterTable(~W);
	V := KSpace(H`qField, #W`CharacterTable);
	return V!DecompositionInGradedGrothendieckGroup(M, H`Group, [1..Ngens(H`Group)]);

end intrinsic;

intrinsic GradedCharacterOfSimple(~H::AlgCheRes, i::RngIntElt)
{}

	W := H`Group;
	if not assigned H`GradedCharactersOfSimples then
		CharacterTable(~W);
		H`GradedCharactersOfSimples := AssociativeArray({1..#W`CharacterTable});
	end if;
	if not IsDefined(H`GradedCharactersOfSimples, i) then
		SimpleModule(~H,i);
		H`GradedCharactersOfSimples[i] := GradedCharacter(H, H`SimpleModules[i]);
	end if;

end intrinsic;

intrinsic GradedCharacterOfSimple(H::AlgCheRes, i::RngIntElt) -> ModTupFldElt
{}

	GradedCharacterOfSimple(~H,i);
	return H`GradedCharactersOfSimples[i];

end intrinsic;

intrinsic GradedCharactersOfSimples(~H::AlgCheRes)
{}
	W := H`Group;
	CharacterTable(~W);
	for i:=1 to #W`CharacterTable do
		GradedCharacterOfSimple(~H, i);
	end for;
end intrinsic;

intrinsic GradedCharactersOfSimples(H::AlgCheRes) -> AlgMat
{}

	GradedCharactersOfSimples(~H);
	W := H`Group;
	N := #H`Group`CharacterTable;
	V := KSpace(H`qField, N);
	CL := Matrix(H`qField, N, N, [V!GradedCharacterOfSimple(H,i) : i in [1..N]]);
	return CL;

end intrinsic;

//============================================================================
intrinsic PoincareSeriesOfSimple(~H::AlgCheRes, i::RngIntElt)
{}

	if not assigned H`PoincareSeriesOfSimples then
		W := H`Group;
		CharacterTable(~W);
		H`PoincareSeriesOfSimples := AssociativeArray({1..#W`CharacterTable});
	end if;
	if not IsDefined(H`PoincareSeriesOfSimples, i) then
		SimpleModule(~H,i);
		H`PoincareSeriesOfSimples[i] := H`qField!(PoincareSeries(H`SimpleModules[i]));
	end if;

end intrinsic;

intrinsic PoincareSeriesOfSimple(H::AlgCheRes, i::RngIntElt) -> FldElt
{}

	PoincareSeriesOfSimple(~H,i);
	return H`PoincareSeriesOfSimples[i];

end intrinsic;

intrinsic PoincareSeriesOfSimples(~H::AlgCheRes)
{}

	W := H`Group;
	CharacterTable(~W);
	for i:=1 to #W`CharacterTable do
		PoincareSeriesOfSimple(~H,i);
	end for;

end intrinsic;

intrinsic PoincareSeriesOfSimples(H::AlgCheRes) -> SeqEnum
{}

	PoincareSeriesOfSimples(~H);
	W := H`Group;
	CharacterTable(~W);
	return [ H`PoincareSeriesOfSimples[i] : i in [1..#W`CharacterTable] ];

end intrinsic;

//============================================================================
intrinsic IdentifyModule(H::AlgCheRes, M::ModGrOld : UseCharacters:=true) -> RngIntElt
{}

	d := Minimum(SequenceToSet(M`RowDegrees));
	Md := GModule(H`Group, [ Matrix(M`HomogeneousComponentMatrices[<i,d>]) : i in [1..Ngens(H`Group)]]);
	ddec := DecompositionInGrothendieckGroup(Md : UseCharacters:=UseCharacters);
	supp := Support(ddec);
	if #supp gt 1 then
		error "No unique lowest component";
	end if;
	supp := SetToSequence(supp)[1];
	if ddec[supp] ne 1 then
		error "No unique lowest component";
	end if;
	return supp;

end intrinsic;


//============================================================================
intrinsic GradedDecompositionMatrix(~H::AlgCheRes, i::RngIntElt)
{}

	if not assigned H`GradedDecompositionMatrix then
		W := H`Group;
		CharacterTable(~W);
		H`GradedDecompositionMatrix := AssociativeArray({1..#W`CharacterTable});
	end if;
	if not IsDefined(H`GradedDecompositionMatrix, i) then
		GradedCharactersOfSimples(~H);
		N := #H`Group`CharacterTable;
		V := KSpace(H`qField, N);
		CLspace := KSpaceWithBasis([ V!(H`GradedCharactersOfSimples[i]) : i in [1..N] ]);
		H`GradedDecompositionMatrix[i] := V!Coordinates(CLspace, GradedCharacterOfVerma(H,i));
	end if;

end intrinsic;

intrinsic GradedDecompositionMatrix(H::AlgCheRes, i::RngIntElt) -> ModTupFldElt
{}

	GradedDecompositionMatrix(~H,i);
	return H`GradedDecompositionMatrix[i];

end intrinsic;

intrinsic GradedDecompositionMatrix(~H::AlgCheRes)
{}

	W := H`Group;
	CharacterTable(~W);
	for i:=1 to #W`CharacterTable do
		GradedDecompositionMatrix(~H,i);
	end for;

end intrinsic;

intrinsic GradedDecompositionMatrix(H::AlgCheRes) -> AlgMat
{}

	GradedDecompositionMatrix(~H);
	W := H`Group;
	CharacterTable(~W);
	N := #W`CharacterTable;
	V := KSpace(H`qField, N);
	D := Matrix(H`qField, N, N, [V!GradedDecompositionMatrix(H,i) : i in [1..N]]);
	return D;

end intrinsic;

//=============================================================================
intrinsic GradedCartanMatrix(~H::AlgCheRes)
{}

	if not assigned H`GradedCartanMatrix then
		GradedDecompositionMatrix(~H);
		D := GradedDecompositionMatrix(H);
		H`GradedCartanMatrix := Transpose(D)*D;
	end if;

end intrinsic;

intrinsic GradedCartanMatrix(H::AlgCheRes) -> AlgMat
{}

	GradedCartanMatrix(~H);
	return H`GradedCartanMatrix;

end intrinsic;

intrinsic RepresentationTheory(H::AlgCheRes)
{}

	D:=GradedDecompositionMatrix(H);
	C:=GradedCartanMatrix(H);
	CDelta:=GradedCharactersOfVermas(H);
	CL:=GradedCharactersOfSimples(H);
	fams,sigma := Families(D);

	cparam := "[";
	counter := 0;
	for i in Domain(H`cParameter) do
		cparam *:= Sprint(H`cParameter(i));
		counter +:= 1;
		if counter lt #Domain(H`cParameter) then
			cparam *:= ",";
		end if;
	end for;
	cparam *:= "]";
	printf "c-parameter: %o\n\n", cparam;
	printf "==== Families ====\n";
	for i:=1 to #fams do
		printf "{";
		for j:=1 to #fams[i] do
			printf "%o", H`Group`CharacterNames[fams[i][j]];
			if j lt #fams[i] then
				printf ",";
			end if;
		end for;
		printf "}";
		if i lt #fams then
			printf ", ";
		end if;
	end for;
	printf "\n\n";

	printf "==== Graded decomposition matrix (family-wise) ====\n";
	for F in fams do
		DF := Submatrix(D, IndexedSetToSequence(F), IndexedSetToSequence(F));
		charnames := [H`Group`CharacterNames[i] : i in F];
		MediaWiki(DF, "Latex" : ColHeader:=charnames, RowHeader:=charnames);
	end for;
	printf "\n";

	printf "==== Graded Cartan matrix (family-wise) ====\n";
	for F in fams do
		CF := Submatrix(C, IndexedSetToSequence(F), IndexedSetToSequence(F));
		charnames := [H`Group`CharacterNames[i] : i in F];
		MediaWiki(CF, "Latex" : ColHeader:=charnames, RowHeader:=charnames);
	end for;
	printf "\n";

	printf "==== Graded characters of simples ====\n";
	CLsigma := Permute(CL,sigma);
	charnames := [H`Group`CharacterNames[i] : i in sigma];
	MediaWiki(CLsigma, "Latex" : ColHeader:=charnames, RowHeader:=charnames);
	printf "\n";

	printf "==== Graded characters of standards ====\n";
	CDeltasigma := Permute(CDelta,sigma);
	charnames := [H`Group`CharacterNames[i] : i in sigma];
	MediaWiki(CDeltasigma, "Latex" : ColHeader:=charnames, RowHeader:=charnames);

end intrinsic;

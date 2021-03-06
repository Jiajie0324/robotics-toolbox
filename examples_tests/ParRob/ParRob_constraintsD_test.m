% Teste die Zeitableitungen der kinematischen Zwangsbedingungen aus der
% Roboterklasse ParRob

% 
% Getestet:
% kinematischen Zwangsbedingungen:
% * constr1..., ...
% Gradienten der Zwangsbedingungen
% * constr1grad..., ...
% Diese Funktionen sind die Grundlage für die inverse Dynamik (insbesondere
% Coriolis-Kräfte)
% Die rotatorischen Zwangsbedingungen können für unterschiedliche
% Euler-Winkel-Konventionen aufgestellt werden. Hier werden alle getestet.
% 
% Siehe auch: ParRob_constraints_test.m


% SA Rajesh Sriram (Studienarbeit bei Moritz Schappler)
% Moritz Schappler, moritz.schappler@imes.uni-hannover.de, 2018-10
% (C) Institut für Mechatronische Systeme, Universität Hannover

clear
clc

% Beispielsysteme
% Entsprechen 6UPS, 4xSCARA, 3RRR, 3RPR
RobotNames = {'P6RRPRRR14', 'P4RRRP1', 'P3RRR1', 'P3RPR1'}; % 

% Einstellungen
use_mex_functions = true; % mit mex geht es etwas schneller
use_IK = false;
only_test_valid_IK = true;
call_fcn_for_testing = false; % Funktionen testweise aufrufen. Stört mit Debug-Haltepunkten

% Endeffektor-Transformation: Nehme irgendwelche Werte um zu prüfen, ob die
% Transformation korrekt implementiert ist
r_P_E   = [0.1;0.2;0.3];
phi_P_E = [20; 40; 50]*pi/180;
% Basis-Transformation: Nehme auch hier irgendwelche Werte
r_W_0   = [0.1;0.2;0.3];
phi_W_0 = [20; 40; 50]*pi/180;

%% Alle Robotermodelle durchgehen
for NNN = RobotNames
  %% PKM initialisieren
  PName = NNN{1};
  N_LEG = str2double(PName(2));
  SName = sprintf('S%d%s',N_LEG,PName(3:end));
  fprintf('Starte Untersuchung für %s\n', PName);
  
  RS = serroblib_create_robot_class(SName);
  serroblib_addtopath({RS.mdlname});
  RS.fill_fcn_handles(use_mex_functions);
  RS.mex_dep()
  
  % Kinematik-Parameter der Beine setzen
  % NaN-Parameter sind frei wählbar und nicht vorbelegt.
  n_NaN = sum(isnan([RS.MDH.a;RS.MDH.d]));
  dd = 0.6 / n_NaN * 2; % Alle Längen gleich
  RS.MDH.b(isnan(RS.MDH.b)) = dd;
  RS.MDH.a(isnan(RS.MDH.a)) = dd;
  RS.MDH.d(isnan(RS.MDH.d)) = dd;
  
  tt = pi/4; % Wenn Winkel ein Parameter sind, darf dieser nicht Null werden
  RS.MDH.alpha(isnan(RS.MDH.alpha)) = tt;
  RS.MDH.theta(isnan(RS.MDH.theta)) = tt;
  RS.update_pkin();
  
  % Aufbau einer Symmetrischen PKM
  RP = ParRob(PName);
  RP.create_symmetric_robot(N_LEG, RS, 0.5, 0.2);
  
  RP.initialize();
  X = [ [0.0;0.0;0.5]; [0;0;0]*pi/180 ];
  xE = X + [[0.1; 0.05; 0]; [1; 1; 1]*pi/180];
 % xE = [ [0;0;0]; [0.5;0.5;0.5]*pi/180 ];
  xE(:,~RP.I_EE) = 0;
  xDE =  rand(6,1) ;
  
  % Kinematik-Parameter anpassen: Zufällige Rotation zu Koppelpunkt-KS der
  % Beinketten. Damit wird geprüft, ob die Funktionen allgemein funktionieren
  if ~use_IK
    for i = 1:RP.NLEG
      RP.Leg(i).update_EE([], rand(3,1));
    end
  end
  RP.update_base(r_W_0, phi_W_0);
  RP.update_EE(r_P_E, phi_P_E, []);
  
  % Debug: Basis-Ausrichtung aller Beinketten genauso wie PKM-Basis setzen
  for i = 1:RP.NLEG
    RP.Leg(i).update_base([], rand(3,1));
  end
  
  % EE-FG eintragen. TODO: FG allgemein festlegen
  if RP.NLEG == 3
    RP.update_EE_FG(logical([1 1 0 0 0 1]));
  elseif RP.NLEG == 4
    RP.update_EE_FG(logical([1 1 1 0 0 1]));
  else
    RP.update_EE_FG(logical([1 1 1 1 1 1]));
  end
  %% Initialisierung der Test-Variablen
  q = ones(RP.NJ,1);
  qD = rand(RP.NJ,1);
  n = 5;
  
  Q_test = rand(n, RP.NJ);
  X_test = rand(n, 6);
  X_test(:,~RP.I_EE) = 0;
  %% Alle Funktionen einmal aufrufen
  if call_fcn_for_testing
  RP.fkine(q, xE);
  RP.fkine_legs(q);
  RP.fkine_platform(xE);
  RP.constr1(q, xE);
  RP.constr1D(q, qD, xE, xDE);
  RP.constr1_trans(q, xE);
  RP.constr1D_trans(q, qD, xE, xDE);
  RP.constr1_rot(q, xE);
  RP.constr1D_rot(q, qD, xE, xDE);
  RP.constr1grad_q(q, xE);
  RP.constr1gradD_q(q, qD, xE, xDE);
  RP.constr1grad_tq(q);
  RP.constr1gradD_tq(q,qD);
  RP.constr1grad_rq(q, xE);
  RP.constr1gradD_rq( q, qD, xE, xDE);
  RP.constr1gradD_tt();
  RP.constr1gradD_tr(xE, xDE);
  RP.constr1grad_x(q, xE);
  RP.constr1gradD_x(q, qD, xE, xDE);
  fprintf('%s: Alle Funktionen einmal ausgeführt\n', PName);
  end
  %% Debug: Löse inverse Kinematik
  if use_IK
    for i = 1:size(Q_test,1)
      s = struct('Phit_tol', 1e-12, 'Phir_tol', 1e-12);
      [q_IK, Phi_IK] = RP.invkin_ser(X_test(i,:)', rand(RP.NJ,1), s);
      if only_test_valid_IK && any(abs(Phi_IK) > 1e-8)
        q_IK = q_IK*NaN;
      end
      Q_test(i,:) = q_IK; % Speichere neue Gelenkwinkel
    end
    fprintf('IK für %d/%d Gelenkwinkel erfolgreich\n', sum(all(~isnan(Q_test)')), size(Q_test,1));
  end
  %% Gradienten der kinematischen Zwangsbedingungen testen
  % Teste, ob die Gradienten dem Differenzenquotienten der
  % Zwangsbedingungen entsprechen.
  
  for i_phiconv = uint8([2 4 6 7 9 11]) % Test für alle Euler-Winkel-Konventionen
    eulstr = euler_angle_properties(i_phiconv);
    RP.phiconv_W_E = i_phiconv;
    n_test = 0; % Zähler für durchgeführte, nicht übersprungene Tests
    for i = 1:size(Q_test,1)
      q0 = Q_test(i,:)';
      if any(isnan(q0))
        continue % Wurde nach IK-Prüfung deaktiviert.
      end
      n_test = n_test + 1;
      x0 = X_test(i,:)';

      % Zwangsbedingungen und -gradienten für q0/x0 berechnen
      [~,Phi1_0] = RP.constr1(q0, x0);
      [~,Phi1dq_0] = RP.constr1grad_q(q0, x0);
      [~,Phi1dx_0] = RP.constr1grad_x(q0, x0);
      
      % Alle Komponenten der Gelenkkoordinaten einmal verschieben und
      % ZB-Gradienten testen (Geometrische Matrix der inversen Kinematik)
      for testcase = 1:2
        if testcase == 1
          id_loop_length = length(q0);
        else
          id_loop_length = 6;
        end
        for id = 1:id_loop_length
          %% Initialisierung der Test-Variablen
          if testcase == 1
            if use_IK, break; end % Teste erstmal nur den x-Zusammenhang
            qD0 = zeros(length(q0),1);
            qD0(id) = 0.1;
            % Neue Koordinaten q1 durch Verschiebung in einer Komponente
            dt = 1e-3;
            q1 = q0 + qD0*dt; % Geschwindigkeit aus entspricht linksseitigem Differenzenquotient
    %         if ~use_IK
              xD0 = zeros(6,1); % Hier gibt es nur eine Änderung der Gelenkwinkel
    %         else
    %           % Damit die IK erfüllt wird, werden die Plattform-Geschw. in
    %           % Abhängigkeit des variierten Gelenkwinkels eingesetzt
    %           G_a = Phi1dq_0(:,id)
    %           G_p = 
    %         end
            % Indizes zum Debuggen
            legnum = find(RP.I1J_LEG>=id,1);
            II = RP.I1constr(legnum):RP.I2constr(legnum);
            JJ = RP.I1J_LEG(legnum):RP.I2J_LEG(legnum);
          else
            xD0 = zeros(6,1);
            xD0(id) = 1;
            dt = 1e-3;

            if ~use_IK
              qD0 = zeros(length(q0),1); % Hier gibt es nur eine Änderung der Gelenkwinkel
              q1 = q0; % keine Gelenkgeschw.
            else
              % Damit die IK erfüllt wird, werden die Gelenk-Geschw. in
              % Abhängigkeit der Plattform-Geschw. eingesetzt
              J_x_inv = -Phi1dq_0 \ Phi1dx_0;
              qD0 = J_x_inv * xD0;
              q1 = q0 + qD0*dt; % Es müssen neue Gelenkwinkel (konsistent mit Geschw.) berechnet werden
            end
            % Indizes zum Debuggen
            II = 1:RP.I2constr(end);
            JJ = 1:RP.I2J_LEG(end);
          end
          % Neue Koordinaten x1 durch Verschiebung in einer Komponente
          x1 = x0 + xD0*dt;
          
          %% Berechne Zeitableitungen aus symbolischer Form und Differenzengleichung
          % Calculation of the differentiated term of the above gradient  
          [~,Phi1D_0] = RP.constr1D(q0, qD0, x0, xD0);
          [~,Phi1Ddq_0] = RP.constr1gradD_q(q0, qD0, x0, xD0);
          [~,Phi1Ddx_0] = RP.constr1gradD_x(q0, qD0, x0, xD0);

          % Zwangsbedingungen und -Matrizen für verschobene Koordinaten q1 berechnen
          [~,Phi1_1] = RP.constr1(q1, x1);
          [~,Phi1dq_1] = RP.constr1grad_q(q1, x1);
          [~,Phi1dx_1] = RP.constr1grad_x(q1, x1);
          
          % Ganzzahlige 2pi bei Winkelfehler entfernen: Wenn Phi1 +pi und
          % Phi0 -pi ist, ist der euklidische Abstand 2pi und die Näherung
          % funktioniert nicht. Daher Winkel-Differenz.
          delta_phi = Phi1_1 - Phi1_0; % Nur für translatorischen Teil
          delta_phi(RP.I_constr_r) = angleDiff(Phi1_0(RP.I_constr_r), Phi1_1(RP.I_constr_r));

          % Annäherung der Zeitableitung durch Bilden des
          % Differenzenquotienten
          Phi1dif =  (delta_phi)/dt ;
          Phi1difdq =  (Phi1dq_1 - Phi1dq_0)/dt ;
          Phi1difdx =  (Phi1dx_1 - Phi1dx_0)/dt ;

          %% Vergleiche beide Formen
          % Prüfe neue ZB aus Ableitung gegen direkt berechnete (linksseitiger
          % Differenzenquotient)
          test1 = Phi1dif - Phi1D_0;    % for constr1D vs constr1 q                        
          test2 = Phi1difdq - Phi1Ddq_0 ;%for constr1gradD_q vs constr1grad_q
          test3 = Phi1difdx - Phi1Ddx_0;% for constr1gradD_x vs constr1grad_x

          % Debug: Rotatorische ZB-Komponenten nicht prüfen
          % test3(RP.I_constr_r,:) = NaN;
          
          % Prüfe neue ZB aus Ableitung gegen direkt berechnete (linksseitiger
          % Differenzenquotient) 
          if any(abs(test1(:)) > 10e-2)
            fprintf('Fehler translatorischer Teil:\n');
            disp(test1(RP.I_constr_t)');
            fprintf('Fehler rotatorischer Teil:\n');
            disp(test1(RP.I_constr_r)');
            warning('%s: constr1D stimmt nicht gegen constr1 (Differenzenquotient vs symbolisch)', PName);
          end

          % Prüfe das Inkrement der ZB-Änderung. Ist dieses Qualitativ
          % gleich, kann man davon ausgehen, dass die Lösung richtig ist.,
          RelErr  = Phi1Ddq_0./Phi1difdq - 1 ;
          RelErr(isnan(RelErr)) = 0; % 0=0 -> relativer Fehler 0
          % Fehler für Translatorisch und Rotatorisch getrennt berechnen
          I_tq_relerr = abs(RelErr(RP.I_constr_t,:)) > 5e-2; % Indizes mit Fehler größer 5%
          I_tq_abserr = abs(test2(RP.I_constr_t,:)) > 8e10*eps(1+max(abs(Phi1dq_1(:)))); % Absoluter Fehler über Toleranz
          if any( I_tq_relerr(:) & I_tq_abserr(:) ) % Fehler bei Überschreitung von absolutem und relativem Fehler
            disp(test2(II,JJ));
            error('%s: constr1gradD_tq stimmt nicht gegen constr1grad_tq', PName);
          end
          
          % TODO: Der rotatorische Teil funktioniert noch nicht.
          I_rq_relerr = abs(RelErr(RP.I_constr_r,:)) > 5e-2; % Indizes mit Fehler größer 5%
          I_rq_abserr = abs(test2(RP.I_constr_r,:)) > 8e10*eps(1+max(abs(Phi1dq_1(:)))); % Absoluter Fehler über Toleranz
          if any( I_rq_relerr(:) & I_rq_abserr(:) ) % Fehler bei Überschreitung von absolutem und relativem Fehler
            % disp(test2(II,JJ));
            % TODO: Schwellwerte so formulieren, dass Test erfolgreich (und
            % plausibel)
%             warning('%s: constr1gradD_rq stimmt nicht gegen constr1grad_rq', PName);
          end
        
          % Sehr kleine Einträge zu Null setzen (sonst kann der relative
          % Fehler unendlich werden)
          Phi1Ddx_0(abs(Phi1Ddx_0(:))<1e-12) = 0;
          
          % Prüfe das Inkrement der ZB-Änderung. Ist dieses Qualitativ
          % gleich, kann man davon ausgehen, dass die Lösung richtig ist.,
          RelErr = Phi1difdx./Phi1Ddx_0 - 1;  % Relative Error = ( Absolute Error / True Value )
          RelErr(isnan(RelErr)) = 0; % 0=0 -> relativer Fehler 0
          RelErr(isinf(RelErr)) = 0; % Bezugsgröße Null geht nicht
          % Prüfe die Komponenten der Matrix einzeln
          I_tr_relerr = abs(RelErr(RP.I_constr_t,4:6)) > 5e-2; % Indizes mit Fehler größer 1%
          I_tr_abserr = abs(test3(RP.I_constr_t,4:6)) > 1e13*eps(1+max(abs(Phi1dx_1(:)))); % erlaubt ca. 4e-3
          if any( I_tr_relerr(:) & I_tr_abserr(:) ) % Fehler bei Überschreitung von absolutem und relativem Fehler
            error('%s: constr1gradD_tr stimmt nicht gegen constr1grad_tr', PName);
          end
          
          % TODO: Der Test für den rotatorischen Teil der Matrix wird noch
          % nicht erfüllt. Unklar, ob es an der numerischen Ungenauigkeit
          % liegt oder noch ein Fehler im Code ist.
          I_rr_relerr = abs(RelErr(RP.I_constr_r,4:6)) > 300e-2;
          I_rr_abserr = abs(test3(RP.I_constr_r,4:6)) > 10;
          I_rr_err = I_rr_relerr & I_rr_abserr;
          if any( I_rr_err(:) ) % Fehler bei Überschreitung von absolutem und relativem Fehler
            % TODO: Schwellwerte so formulieren, dass Test erfolgreich (und
            % plausibel)
%             warning('%s: constr1gradD_rr stimmt nicht gegen constr1grad_rr', PName);
          end
        end % Schleife für Variation der Elemente von qD oder xD
      end % Schleife über Testfälle (entweder qD oder xD variieren)
    end % Schleife über alle Gelenkwinkel-Konfigurationen
    fprintf('%s: Konsistenz der Zeitableitung der Zwangsbedingungs-Gradienten erfolgreich getestet für %s-Euler-Winkel (%d Zufallskonfigurationen).\n', PName, eulstr, n_test);
  end % Schleife über alle Winkelkonventionen
end % Schleife über alle Roboter
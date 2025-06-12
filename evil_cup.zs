//-------------------------------------------------
// False Grail
//-------------------------------------------------
class HDFalseGrail:HDWeapon{
	default{
		//$Category "Items/Hideous Destructor/Magic"
		//$Title "Evil Cup"
		//$Sprite "CUPPA0"

		+inventory.ishealth
		+weapon.wimpy_weapon
		+weapon.no_auto_switch
		+inventory.invbar
		+hdweapon.fitsinbackpack
		weapon.selectionorder 999;
		inventory.pickupmessage "Robbed a relic";
		inventory.pickupsound "potion/swish";
		tag "Evil Cup";
		inventory.icon "CUPPE0";
		scale 0.3;
		hdweapon.refid "cup";


// Add a gilded tazze variety sometime

	}
	override string,double getpickupsprite(){return "CUPPA0",1.;}
	override double weaponbulk(){
		return (ENC_POTION*0.7)+(ENC_POTION*0.04)*weaponstatus[HDSP_AMOUNT];
	}
	override string gethelptext(){LocalizeHelp();
		return LWPHELP_FIRE..StringTable.Localize("$HEALWH_FIRE")
		;
	}
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		sb.drawimage(
			"CUPPA0",(-23,-7),
			sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT
		);
		sb.drawwepnum(hdw.weaponstatus[HDSP_AMOUNT],6);
	}
	override int getsbarnum(int flags){
		return weaponstatus[HDSP_AMOUNT];
	}
	override void InitializeWepStats(bool idfa){
		weaponstatus[HDSP_AMOUNT]=6;
	}
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){
		if(weaponstatus[INJECTS_AMOUNT]<1)doselect=false;
		return GetSpareWeaponRegular(newowner,reverse,doselect);
	}
	states(actor){
	spawn:
		TNT1 A 1 nodelay{
			if(weaponstatus[INJECTS_AMOUNT]>0){
				if(Wads.CheckNumForName("id",0)!=-1){
					setstatelabel("jiggling");
					return;
				}
				scale=(0.5,0.5);
				if(floorz<pos.z)setstatelabel("plucked");
				else setstatelabel("planted");
			}
		}
		CUPP A 0{
			actor a=null;
			a=spawn("ChoosedPoorly",pos,ALLOW_REPLACE);
			a.A_StartSound("potion/open",CHAN_BODY);
			a.angle=angle;a.pitch=pitch;a.target=target;a.vel=vel;
		}
		stop;
	planted:
		CUPP ABCDCB 4;
		loop;
	plucked:
		CUPP E -1;
		stop;
	jiggling:
		CUPP ABCDCB 2 A_SetTics(random(1,3));
		loop;
	}
	states{
	select:
		TNT1 A 0{
			if(DoHelpText())A_WeaponMessage(Stringtable.Localize("\ci::: \ckEvil Cup \ci:::\c-\n\n\nMade by\ndesperate human hands.\n\nIn Vain."));
			A_StartSound("potion/swish",8,CHANF_OVERLAP);
		}
		goto super::select;
	deselect:
		TNT1 A 10{
			if(invoker.weaponstatus[HDSP_AMOUNT]<1){
				DropInventory(invoker);
				return;
			}
			A_StartSound("potion/swish",8,CHANF_OVERLAP);
		}
		TNT1 A 0 A_Lower(999);
		wait;
	fire:
		TNT1 A 0{
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKFACE);
			if(blockinv){
				A_TakeOffFirst(blockinv.gettag(),2);
				A_Refire("nope");
			}
		}
		TNT1 A 4 A_WeaponReady(WRF_NOFIRE);
		TNT1 A 1{
			A_StartSound("potion/open",CHAN_WEAPON);
			A_Refire();
		}
		TNT1 A 0 A_StartSound("potion/swish",8);
		goto nope;
	hold:
		TNT1 A 1;
		TNT1 A 0{
			A_WeaponBusy();
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKFACE);
				if(blockinv){
					A_TakeOffFirst(blockinv.gettag(),2);
					A_Refire("nope");
				}else if(pitch>-25){
					A_MuzzleClimb(0,-8);
					A_Refire();
				}else{
					A_Refire("inject");
				}
		}
		TNT1 A 0 A_StartSound("potion/away",CHAN_WEAPON,volume:0.4);
		goto nope;
	inject:
		TNT1 A 7{
			A_MuzzleClimb(0,-2);
			if(invoker.weaponstatus[HDSP_AMOUNT]>0){
				invoker.weaponstatus[HDSP_AMOUNT]--;
				A_StartSound("potion/chug",CHAN_VOICE);
				HDF.Give(self,"SatanicPact",6);
			}
		}
		TNT1 AAAAA 1 A_MuzzleClimb(0,0.1);
		TNT1 A 5 A_JumpIf(!pressingfire(),"injectend");
		goto hold;
	injectend:
		TNT1 A 6;
		TNT1 A 0{
			if(invoker.weaponstatus[HDSP_AMOUNT]>0)A_StartSound("potion/away",CHAN_WEAPON,volume:0.4);
		}
		goto nope;
	}
}


class SatanicPact:HDDrug{
	override void doeffect(){
		let hdp=hdplayerpawn(owner);

		double ret=min(0.13,amount*0.666);
		if(hdp.strength<1.+ret)hdp.strength+=0.006;
	}
	override void pretravelled(){
		let hdp=hdplayerpawn(owner);

		HDBleedingWound bldw=null;
		thinkeriterator bldit=thinkeriterator.create("HDBleedingWound");
		while(bldw=HDBleedingWound(bldit.next())){
			if(
				bldw
				&&bldw.bleeder==hdp
			){
				double cost=
					bldw.depth
					+bldw.width*0.777
					+bldw.patched*0.888
					+bldw.healing*0.555
				;
				if(amount<cost)break;
				amount-=int(cost);
				bldw.depth=0;
				bldw.width=0;
				bldw.patched=0;
				bldw.healing=0;
			}
		}

		let bloodloss=(hdp.bloodloss>>4);
		bloodloss=min(bloodloss,amount);
		if(bloodloss>0){
			amount-=bloodloss;
			hdp.bloodloss-=(bloodloss<<4);
		}

		return;
	}


	override void OnHeartbeat(hdplayerpawn hdp){
		if(amount<1)return;

		if(hdp.beatcap<HDCONST_MINHEARTTICS){
			hdp.beatcap=max(hdp.beatcap,HDCONST_MINHEARTTICS+5);
			if(!random(0,99))amount--;
		}
		if(hdp.countinv("HealingMagic")){
			hdp.A_TakeInventory("SatanicPact",8);
			amount--;
		}
		if(hdp.countinv("hdstim")){
			hdp.A_TakeInventory("SatanicPact",8);
			amount--;
		}

		if(hdp.bloodloss>0)hdp.bloodloss-=13;

		if(
			hd_nobleed
			&&hdp.health<hdp.healthcap
		)hdp.givebody(1);

		//heal shorter-term damage
		let hdbw=hdbleedingwound.findbiggest(hdp,HDBW_FINDPATCHED|HDBW_FINDhealing);
		if(hdbw){
			double addamt=min(0.,hdbw.depth);
			hdbw.depth-=addamt;
			hdbw.patched+=addamt;
			addamt=min(0.8,hdbw.patched);
			hdbw.patched-=addamt;
			hdbw.healing+=addamt;
			hdbw.healing=max(0,hdbw.healing-0.6);
			amount--;
		}
		if(
				hdp.burncount>0
				||hdp.oldwoundcount>0
				||hdp.aggravateddamage>0
			){
				hdp.burncount--;
				hdp.oldwoundcount--;
				hdp.aggravateddamage--;
				amount--;
			}

				if(hdp.beatcounter%40==0){
			//time wounds all the heals as we faaadee out of vieeew
		let hdbw=hdbleedingwound.findbiggest(hdp,HDBW_FINDPATCHED|HDBW_FINDhealing);
		if(hdbw){	
			hdp.burncount+=30;
			double addamt=min(20.,hdbw.depth);
			hdbw.depth+=addamt;
			hdbw.patched-=addamt;
			addamt=min(0.8,hdbw.patched);
			hdbw.patched+=addamt;
			hdbw.healing-=addamt;
			hdbw.healing=max(0,hdbw.healing+0.6);
			amount-=10;
		}
			
			if(
				hdp.beatcounter%181==0
			){
				hdp.A_Log(Stringtable.Localize("Sinner..."),true);
				amount-=40;
				hdp.incaptimer=min(0,hdp.incaptimer);
				hdp.stunned=9;
				plantbit.spawnplants(hdp,33,144);
				switch(random(0,3)){
				case 0:
					{
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					break;	
					}
					break;
				case 1:
					{
					hdp.aggravateddamage+=20;
					hdp.burncount+=20;
					for(int i=0;i<2;i++){
						let bld=hdbleedingwound.findbiggest(hdp,HDBW_FINDPATCHED|HDBW_FINDhealing);
						if(bld)bld.destroy();
					}
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					break;	
					}
					break;
				default:
					hdp.aggravateddamage+=20;
					hdp.burncount+=20;
					for(int i=0;i<2;i++){
						let bld=hdbleedingwound.findbiggest(hdp,HDBW_FINDPATCHED|HDBW_FINDhealing);
						if(bld)bld.destroy();
					}

					blockthingsiterator healit=
						blockthingsiterator.create(hdp,1024);
					while(healit.next())

					if(!random(0,3))spawn("BFGNecroShard",hdp.pos,ALLOW_REPLACE);
					break;
				}

			}
		}

		if(hd_debug>=4)console.printf("HEALZ "..amount.."  = "..hdp.strength);
	}
}
enum HDSatanicPactNums{
	HDSP_AMOUNT=1,
	HDEVIL_CURSE=1,
}




class ChoosedPoorly:SpentBottle{
	default{
		alpha 0.6;renderstyle "translucent";
		bouncesound "bauble/away";
		bouncefactor 0.4;scale 0.3;
		translation "10:15=241:243","150:151=206:207";
		radiusdamagefactor 0.04;pushfactor 1.4;maxstepheight 2;mass 23;
	}
	override void ondestroy(){
		plantbit.spawnplants(self,7,33);
		actor.ondestroy();
	}
	states{
	spawn:
		CUPP F 0 nodelay{
			if(Wads.CheckNumForName("id",0)==-1)scale=(0.5,0.5);
		}
		goto spawn2;
	death:
		---- A -1 A_JumpIf(Wads.CheckNumForName("id",0)!=-1,1);
		stop;
		---- A 100{
			if(random(0,7))roll=randompick(90,270);else roll=0;
			if(roll==270)scale.x*=-1;
		}
		---- A random(2,4){
			if(frandom(0.1,0.9)<alpha){
				angle+=random(-12,12);pitch=random(45,90);
				actor a=spawn("HDGunSmoke",pos,ALLOW_REPLACE);
				a.scale=(0.4,0.4);a.angle=angle;
			}
			A_FadeOut(frandom(-0.03,0.032));
		}wait;
	}
}
//no cork


################################################# Processing  ##########################################
traits <-read.csv("./output/biomass_core_leaf_spei_final.csv")
########################################################################################################
names(traits)
nrow(traits) # 2788

traits$Ntrt_fac <- as.factor(traits$Ntrt)
traits$Ptrt_fac <- as.factor(traits$Ptrt)
traits$Ktrt_fac <- as.factor(traits$Ktrt)
traits$block_fac <- as.factor(traits$block)
traits$trt_fac <- as.factor(traits$trt)

## add in photosynthetic pathway information
levels(as.factor(traits$Family)) # check Amaranthaceae, Asteraceae, Boraginaceae, Caryophyllaceae, Cyperaceae, Euphorbiaceae,
# Polygonaceae, Poaceae, Scrophulariaceae
# only one!
# C4
#traits$photosynthetic_pathway ='NULL'
traits$photosynthetic_pathway[traits$photosynthetic_pathway == 'NULL'
                              & traits$Family == 'Cyperaceae' & traits$Taxon == 'FIMBRISTYLIS DICHOTOMA'] <- 'C4'

traits$photosynthetic_pathway[traits$photosynthetic_pathway == 'NULL'] <- 'C3'

table(traits$photosynthetic_pathway)
## C4 : 521
## C3: 2267

### calculate SLA #############
traits$sla_m2_g = traits$SLA_v2 * (1/1000000)
hist(traits$sla_m2_g)

### calculate LMA #############
traits$lma = 1/traits$sla_m2_g
hist(traits$lma) # some extremely high values

### calculate narea #############
traits$narea = (traits$leaf_pct_N / 100) * (traits$lma)
hist(traits$narea) # some extremely high values

### calculate nmass #############
traits$nmass = traits$leaf_pct_N
hist(traits$nmass)
hist(traits$leaf_pct_N)

### calculate N: P ratio in leaves #############
traits$leaf_pct_P = traits$leaf_ppm_P/10000 ## transform into percentage
traits$leaf_N_P = traits$leaf_pct_N/traits$leaf_pct_P

### calculate C: N ratio in leaves #############
traits$leaf_N_C = traits$leaf_pct_C/traits$leaf_pct_N


### calculate lai per plot #############
traits$lai = -log(traits$Ground_PAR / traits$Ambient_PAR) / 0.86 # from: http://manuals.decagon.com/Manuals/10242_Accupar%20LP80_Web.pdf page 41
hist(traits$lai)

### calculate par per leaf area to assume par absorbed is reduced in dense canopies: calculation per plot
traits$par_per_leaf_area = traits$par2_gs * ((1 - exp(-0.5 * traits$lai)) / traits$lai) # from Dong et al. (2007) eqn 2
hist(traits$par_per_leaf_area)

### calculate biomass for each species depending on the percentage max-cover for each species ###############
traits$spp_live_mass = traits$live_mass * (traits$max_cover / 100)
hist(traits$spp_live_mass)


## calculate big delta C13 from small delta 
traits$delta = ((-0.008 - traits$leaf_C13_delta_PDB * 0.001) / (1 + traits$leaf_C13_delta_PDB * 0.001)) * 1000
hist(traits$delta)

##### calculate chi for C3 plants #################### 
traits$chi[traits$photosynthetic_pathway == 'C3'] = 
  (traits$delta[traits$photosynthetic_pathway == 'C3'] * 0.001 - 0.0044) / (0.027 - 0.0044)
hist(traits$chi)

##### calculate chi for C4 plants #################### 
traits$chi[traits$photosynthetic_pathway == 'C4'] = 
  (traits$delta[traits$photosynthetic_pathway == 'C4'] * 0.001 - 0.0044) / ((-0.0057 + 0.03*0.4) - 0.0044)


hist(traits$chi)

#### create a new column for fence #################
traits$fence <- 'no'
traits$fence[traits$trt == 'Fence' | traits$trt == 'NPK+Fence'] <- 'yes'

################### transform some variables into log to get normal distribution #####################################

traits$loglma <- log(traits$lma)
hist(traits$loglma)

traits$lognarea <- log(traits$narea)
hist(traits$lognarea)

traits$lognmass <- log(traits$nmass)
hist(traits$lognmass)

names(traits)
traits$log_spp_live_mass <- log(traits$spp_live_mass)
hist(traits$log_spp_live_mass)

traits$aridity <- traits$p_pet
#################### exclude C points where chi is higher than 0.1 and lower than 0.95 ######### 
traits_chi_sub <- subset(traits, chi > 0.1 & chi < 0.95)
nrow(traits_chi_sub) ### 2106

table(traits_chi_sub$pft) ### 162 C4 remains 
hist(traits_chi_sub$chi) # quasi normal distribution 
hist(traits_chi_sub$p_pet) 

nrow(traits_chi_sub) # 2106
min(traits_chi_sub$chi) # 0.114 
max(traits_chi_sub$chi) # 0.938

length(unique(traits_chi_sub$Taxon)) # 207 species 
length(unique(traits_chi_sub$site_code)) # 26 sites

################# exclusion of fence plots  ###########################
unique(traits_chi_sub$trt)
unique(traits_chi_sub$fence)

## exclusion of fence treatments 
traits_nofence_chi_sub = subset(traits_chi_sub, fence == "no")
traits_nofence_chi_sub$fence
nrow(traits_nofence_chi_sub) ## 1752
length(unique(traits_nofence_chi_sub$Taxon)) # 196 species 
length(unique(traits_chi_sub$site_code)) # 26 sites

min(traits_chi_sub$aridity) # 0.14
max(traits_chi_sub$aridity) # 2.32

write.csv(traits, "./output/traits.csv")
write.csv(traits_chi_sub, "./output/traits_chi_sub.csv")
write.csv(traits_nofence_chi_sub, "./output/traits_nofence_chi_sub.csv")



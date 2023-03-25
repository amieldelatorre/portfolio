import { Experience } from "../models/Experience";

export interface IGetData {
    getExperienceData: () => Experience[];
}


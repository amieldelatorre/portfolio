import { Experience } from "../models/Experience";
import { IGetData } from "./IGetData";
import experienceJSON from "../assets/data/experience.json";

class GetDatafromJSON implements IGetData {

    getExperienceData(): Experience[] {
        let experience: Experience[] = experienceJSON.map((exp) => {
            return new Experience (
                exp.type,
                exp.dateRange,
                exp.title,
                exp.location,
                exp.description,
                exp.sortOrder
            )
        });
        return experience;
    }
}

export const GetDatafromJSONInstance = new GetDatafromJSON();
